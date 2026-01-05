module ImageUpload
  class GcsUploader
    def self.upload(file, filename, upload_type)
      require "google/cloud/storage"
      require "image_processing/vips"

      extension = filename.split(".").last
      temp_file = Tempfile.new([ "resized", ".#{extension}" ])

      begin
        processed_image = ImageProcessing::Vips.source(file.tempfile)
        content_type = process_image(processed_image, upload_type, temp_file.path)

        upload_to_bucket(temp_file.path, filename, content_type)
      rescue => e
        Rails.logger.error "GCS upload error: #{e.class.name} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        { error: "アップロードに失敗しました: #{e.message}" }
      ensure
        temp_file.close
        temp_file.unlink
      end
    end

    private_class_method def self.process_image(processed_image, upload_type, destination)
      case upload_type
      when "content"
        processed_image
          .resize_to_limit(2000, 2000)
          .convert("webp")
          .saver(quality: 70, strip: true)
          .call(destination: destination)
        "image/webp"
      when "hero"
        processed_image
          .resize_to_fill(1920, 1080, crop: :attention)
          .convert("webp")
          .saver(quality: 75, strip: true)
          .call(destination: destination)
        "image/webp"
      else
        processed_image
          .resize_to_fill(1200, 630, crop: :attention)
          .convert("webp")
          .saver(quality: 70, strip: true)
          .call(destination: destination)
        "image/webp"
      end
    end

    private_class_method def self.upload_to_bucket(file_path, filename, content_type)
      project_id = Rails.application.credentials.dig(:gcp, :project_id)
      bucket_name = Rails.application.credentials.dig(:gcp, :bucket)
      credentials = Rails.application.credentials.dig(:gcp, :credentials)

      Rails.logger.info "GCS Upload - Project: #{project_id}, Bucket: #{bucket_name}"

      unless project_id && bucket_name && credentials
        raise "GCS credentials not configured properly. Check credentials.yml.enc"
      end

      storage = Google::Cloud::Storage.new(
        project_id: project_id,
        credentials: credentials
      )

      bucket = storage.bucket(bucket_name)
      unless bucket
        raise "Bucket '#{bucket_name}' not found or not accessible"
      end

      blob = bucket.create_file(
        file_path,
        "images/#{filename}",
        content_type: content_type
      )

      {
        url: blob.public_url,
        markdown: "![画像](#{blob.public_url})"
      }
    end
  end
end
