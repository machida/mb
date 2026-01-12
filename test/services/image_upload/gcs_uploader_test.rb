require "test_helper"

module ImageUpload
  class GcsUploaderTest < ActiveSupport::TestCase
    # Skip GCS tests if google-cloud-storage gem is not available
    # This is expected in development/test environments
    def setup_gcs_mocks
      skip "Google Cloud Storage gem not available" unless defined?(Google::Cloud::Storage)
    end
    setup do
      @temp_file = Tempfile.new([ "test", ".jpg" ])
      @temp_file.write("test image content")
      @temp_file.rewind

      # Create a mock uploaded file
      @uploaded_file = mock("uploaded_file")
      @uploaded_file.stubs(:tempfile).returns(@temp_file)
      @filename = "test_image_#{Time.current.to_i}.webp"
    end

    teardown do
      @temp_file.close
      @temp_file.unlink
    end

    test "should upload content image to GCS" do
      setup_gcs_mocks

      # Mock GCS objects
      mock_storage = mock("storage")
      mock_bucket = mock("bucket")
      mock_blob = mock("blob")

      # Mock credentials
      Rails.application.credentials.stubs(:dig).with(:gcp, :project_id).returns("test-project")
      Rails.application.credentials.stubs(:dig).with(:gcp, :bucket).returns("test-bucket")
      Rails.application.credentials.stubs(:dig).with(:gcp, :credentials).returns({ "type" => "service_account" })

      # Setup mocks
      Google::Cloud::Storage.expects(:new).with(
        project_id: "test-project",
        credentials: { "type" => "service_account" }
      ).returns(mock_storage)

      mock_storage.expects(:bucket).with("test-bucket").returns(mock_bucket)
      mock_bucket.expects(:create_file).with(
        anything,
        "images/#{@filename}",
        content_type: "image/webp"
      ).returns(mock_blob)

      mock_blob.stubs(:public_url).returns("https://example.com/test.webp")

      # Mock image processing chain
      mock_processor = mock("processor")
      mock_resized = mock("resized")
      mock_converted = mock("converted")

      ImageProcessing::Vips.expects(:source).returns(mock_processor)
      mock_processor.expects(:resize_to_limit).with(2000, 2000).returns(mock_resized)
      mock_resized.expects(:convert).with("webp").returns(mock_converted)
      mock_converted.expects(:saver).with(quality: 70, strip: true).returns(mock_converted)
      mock_converted.expects(:call).with(destination: anything).returns(true)

      result = GcsUploader.upload(@uploaded_file, @filename, "content")

      assert_equal "https://example.com/test.webp", result[:url]
      assert_equal "![画像](https://example.com/test.webp)", result[:markdown]
    end

    test "should upload hero image to GCS with correct processing" do
      setup_gcs_mocks

      # Mock GCS objects
      mock_storage = mock("storage")
      mock_bucket = mock("bucket")
      mock_blob = mock("blob")

      # Mock credentials
      Rails.application.credentials.stubs(:dig).with(:gcp, :project_id).returns("test-project")
      Rails.application.credentials.stubs(:dig).with(:gcp, :bucket).returns("test-bucket")
      Rails.application.credentials.stubs(:dig).with(:gcp, :credentials).returns({ "type" => "service_account" })

      # Setup mocks
      Google::Cloud::Storage.expects(:new).returns(mock_storage)
      mock_storage.expects(:bucket).returns(mock_bucket)
      mock_bucket.expects(:create_file).returns(mock_blob)
      mock_blob.stubs(:public_url).returns("https://example.com/hero.webp")

      # Mock image processing chain
      mock_processor = mock("processor")
      mock_resized = mock("resized")
      mock_converted = mock("converted")

      ImageProcessing::Vips.expects(:source).returns(mock_processor)
      mock_processor.expects(:resize_to_fill).with(1920, 1080, crop: :attention).returns(mock_resized)
      mock_resized.expects(:convert).with("webp").returns(mock_converted)
      mock_converted.expects(:saver).with(quality: 75, strip: true).returns(mock_converted)
      mock_converted.expects(:call).with(destination: anything).returns(true)

      result = GcsUploader.upload(@uploaded_file, @filename, "hero")

      assert_equal "https://example.com/hero.webp", result[:url]
    end

    test "should upload og image to GCS" do
      setup_gcs_mocks

      # Mock GCS objects
      mock_storage = mock("storage")
      mock_bucket = mock("bucket")
      mock_blob = mock("blob")

      # Mock credentials
      Rails.application.credentials.stubs(:dig).with(:gcp, :project_id).returns("test-project")
      Rails.application.credentials.stubs(:dig).with(:gcp, :bucket).returns("test-bucket")
      Rails.application.credentials.stubs(:dig).with(:gcp, :credentials).returns({ "type" => "service_account" })

      # Setup mocks
      Google::Cloud::Storage.expects(:new).returns(mock_storage)
      mock_storage.expects(:bucket).returns(mock_bucket)
      mock_bucket.expects(:create_file).returns(mock_blob)
      mock_blob.stubs(:public_url).returns("https://example.com/og.webp")

      # Mock image processing chain
      mock_processor = mock("processor")
      mock_resized = mock("resized")
      mock_converted = mock("converted")

      ImageProcessing::Vips.expects(:source).returns(mock_processor)
      mock_processor.expects(:resize_to_fill).with(1200, 630, crop: :attention).returns(mock_resized)
      mock_resized.expects(:convert).with("webp").returns(mock_converted)
      mock_converted.expects(:saver).with(quality: 70, strip: true).returns(mock_converted)
      mock_converted.expects(:call).with(destination: anything).returns(true)

      result = GcsUploader.upload(@uploaded_file, @filename, "og")

      assert_equal "https://example.com/og.webp", result[:url]
    end

    test "should return error when GCS credentials are missing" do
      setup_gcs_mocks

      Rails.application.credentials.stubs(:dig).with(:gcp, :project_id).returns(nil)
      Rails.application.credentials.stubs(:dig).with(:gcp, :bucket).returns(nil)
      Rails.application.credentials.stubs(:dig).with(:gcp, :credentials).returns(nil)

      # Mock image processing chain
      mock_processor = mock("processor")
      mock_resized = mock("resized")
      mock_converted = mock("converted")

      ImageProcessing::Vips.expects(:source).returns(mock_processor)
      mock_processor.expects(:resize_to_limit).with(2000, 2000).returns(mock_resized)
      mock_resized.expects(:convert).with("webp").returns(mock_converted)
      mock_converted.expects(:saver).with(quality: 70, strip: true).returns(mock_converted)
      mock_converted.expects(:call).with(destination: anything).returns(true)

      result = GcsUploader.upload(@uploaded_file, @filename, "content")

      assert result[:error].present?
      assert_match(/アップロードに失敗しました/, result[:error])
    end

    test "should return error when bucket is not found" do
      setup_gcs_mocks

      mock_storage = mock("storage")

      Rails.application.credentials.stubs(:dig).with(:gcp, :project_id).returns("test-project")
      Rails.application.credentials.stubs(:dig).with(:gcp, :bucket).returns("nonexistent-bucket")
      Rails.application.credentials.stubs(:dig).with(:gcp, :credentials).returns({ "type" => "service_account" })

      Google::Cloud::Storage.expects(:new).returns(mock_storage)
      mock_storage.expects(:bucket).with("nonexistent-bucket").returns(nil)

      # Mock image processing chain
      mock_processor = mock("processor")
      mock_resized = mock("resized")
      mock_converted = mock("converted")

      ImageProcessing::Vips.expects(:source).returns(mock_processor)
      mock_processor.expects(:resize_to_limit).with(2000, 2000).returns(mock_resized)
      mock_resized.expects(:convert).with("webp").returns(mock_converted)
      mock_converted.expects(:saver).with(quality: 70, strip: true).returns(mock_converted)
      mock_converted.expects(:call).with(destination: anything).returns(true)

      result = GcsUploader.upload(@uploaded_file, @filename, "content")

      assert result[:error].present?
      assert_match(/アップロードに失敗しました/, result[:error])
    end

    test "should handle image processing errors" do
      setup_gcs_mocks

      Rails.application.credentials.stubs(:dig).with(:gcp, :project_id).returns("test-project")
      Rails.application.credentials.stubs(:dig).with(:gcp, :bucket).returns("test-bucket")
      Rails.application.credentials.stubs(:dig).with(:gcp, :credentials).returns({ "type" => "service_account" })

      # Make image processing fail
      ImageProcessing::Vips.stubs(:source).raises(StandardError.new("Image processing failed"))

      result = GcsUploader.upload(@uploaded_file, @filename, "content")

      assert result[:error].present?
      assert_match(/アップロードに失敗しました/, result[:error])
    end
  end
end
