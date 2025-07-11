require "test_helper"

class ImageUploadServiceTest < ActiveSupport::TestCase
  def setup
    # VIPSで実際の画像ファイルを作成
    require "image_processing/vips"
    image = Vips::Image.black(100, 100)
    
    @temp_image_file = Tempfile.new([ "test_image", ".jpg" ])
    @temp_image_file.close
    image.write_to_file(@temp_image_file.path)
    
    # ファイルを開いてStringIOに読み込み
    image_data = File.binread(@temp_image_file.path)
    
    @valid_image = Rack::Test::UploadedFile.new(
      StringIO.new(image_data),
      "image/jpeg",
      original_filename: "test.jpg"
    )
    
    @invalid_file = Rack::Test::UploadedFile.new(
      StringIO.new("not an image"),
      "text/plain",
      original_filename: "test.txt"
    )
    
    @large_image = Rack::Test::UploadedFile.new(
      StringIO.new("x" * 6.megabytes),
      "image/jpeg",
      original_filename: "large.jpg"
    )
  end

  def teardown
    @temp_image_file&.unlink
  end

  test "should upload valid image in development" do
    Rails.env.stubs(:production?).returns(false)
    
    result = ImageUploadService.upload(@valid_image)
    
    assert_not result[:error]
    assert result[:url]
    assert result[:markdown]
    assert result[:url].starts_with?("/uploads/images/")
    assert result[:markdown].include?("![画像]")
  end

  test "should reject non-image file" do
    result = ImageUploadService.upload(@invalid_file)
    
    assert_equal "画像ファイルのみアップロード可能です", result[:error]
    assert_nil result[:url]
    assert_nil result[:markdown]
  end

  test "should reject large file" do
    result = ImageUploadService.upload(@large_image)
    
    assert_equal "ファイルサイズは5MB以下にしてください", result[:error]
    assert_nil result[:url]
    assert_nil result[:markdown]
  end

  test "should generate unique filename" do
    Rails.env.stubs(:production?).returns(false)
    
    result1 = ImageUploadService.upload(@valid_image)
    result2 = ImageUploadService.upload(@valid_image)
    
    assert_not_equal result1[:url], result2[:url]
  end

  test "should handle upload errors gracefully" do
    Rails.env.stubs(:production?).returns(false)
    
    # Mock file operations to raise an error
    File.stubs(:open).raises(StandardError.new("File error"))
    
    result = ImageUploadService.upload(@valid_image)
    
    assert_equal "画像処理に失敗しました", result[:error]
  end

  test "VIPS should be working correctly" do
    assert ImageUploadService.vips_working?, "VIPS should be available and working"
  end

  test "should process images with correct format based on upload type" do
    Rails.env.stubs(:production?).returns(false)
    
    # サムネイル用（JPEG形式）
    thumbnail_result = ImageUploadService.upload(@valid_image, upload_type: "thumbnail")
    assert_not thumbnail_result[:error]
    assert thumbnail_result[:url].end_with?(".jpg")
    
    # コンテンツ用（WebP形式）
    content_result = ImageUploadService.upload(@valid_image, upload_type: "content")
    assert_not content_result[:error]
    assert content_result[:url].end_with?(".webp")
  end
end