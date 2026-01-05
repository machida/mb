class ImageUploadService
  EXTENSION = "webp"

  def self.upload(file, upload_type: "thumbnail")
    return { error: "画像ファイルのみアップロード可能です" } unless file.content_type.start_with?("image/")
    return { error: "ファイルサイズは5MB以下にしてください" } if file.size > 5.megabytes

    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "#{timestamp}_#{SecureRandom.hex(8)}.#{EXTENSION}"

    if Rails.env.production?
      ImageUpload::GcsUploader.upload(file, filename, upload_type)
    else
      ImageUpload::LocalUploader.upload(file, filename, upload_type)
    end
  end

  def self.vips_working?
    require "image_processing/vips"

    image = Vips::Image.black(1, 1)

    source_file = Tempfile.new([ "vips_source", ".#{EXTENSION}" ])
    result_file = Tempfile.new([ "vips_result", ".#{EXTENSION}" ])

    source_file.close
    result_file.close

    image.write_to_file(source_file.path)

    ImageProcessing::Vips
      .source(source_file.path)
      .resize_to_limit(10, 10)
      .convert("webp")
      .call(destination: result_file.path)

    File.exist?(result_file.path) && File.size(result_file.path) > 0
  rescue => e
    Rails.logger.error "VIPS test failed: #{e.message}"
    false
  ensure
    source_file&.unlink
    result_file&.unlink
  end
end
