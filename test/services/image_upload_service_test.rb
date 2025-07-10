require "test_helper"

class ImageUploadServiceTest < ActiveSupport::TestCase
  def setup
    @valid_image = Rack::Test::UploadedFile.new(
      StringIO.new("fake image data"),
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
    
    assert_equal "アップロードに失敗しました", result[:error]
  end
end