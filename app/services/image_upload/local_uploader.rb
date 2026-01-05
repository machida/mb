module ImageUpload
  class LocalUploader
    def self.upload(file, filename, upload_type)
      require "image_processing/vips"

      upload_dir = Rails.root.join("public", "uploads", "images")
      FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)

      file_path = upload_dir.join(filename).to_s
      source_path = extract_source_path(file)

      process_image(source_path, upload_type, file_path)

      {
        url: "/uploads/images/#{filename}",
        markdown: "![画像](/uploads/images/#{filename})"
      }
    rescue => e
      Rails.logger.error "Image processing error: #{e.message}"
      { error: "画像処理に失敗しました" }
    ensure
      cleanup_temp_source if defined?(@temp_source) && @temp_source.respond_to?(:unlink)
    end

    private_class_method def self.extract_source_path(file)
      if file.respond_to?(:tempfile)
        if file.tempfile.respond_to?(:path)
          file.tempfile.path
        else
          @temp_source = Tempfile.new([ "upload_source", ".tmp" ])
          @temp_source.binmode
          file.tempfile.rewind
          @temp_source.write(file.tempfile.read)
          @temp_source.close
          @temp_source.path
        end
      else
        file.path
      end
    end

    private_class_method def self.process_image(source_path, upload_type, destination)
      processed_image = ImageProcessing::Vips.source(source_path)

      case upload_type
      when "content"
        processed_image
          .resize_to_limit(2000, 2000)
          .convert("webp")
          .saver(quality: 70, strip: true)
          .call(destination: destination)
      when "hero"
        processed_image
          .resize_to_fill(1920, 1080, crop: :attention)
          .convert("webp")
          .saver(quality: 75, strip: true)
          .call(destination: destination)
      else
        processed_image
          .resize_to_fill(1200, 630, crop: :attention)
          .convert("webp")
          .saver(quality: 70, strip: true)
          .call(destination: destination)
      end
    end

    private_class_method def self.cleanup_temp_source
      @temp_source&.unlink
    end
  end
end
