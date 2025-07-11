class ImageUploadService
  def self.upload(file, upload_type: "thumbnail")
    # ファイルの検証
    return { error: "画像ファイルのみアップロード可能です" } unless file.content_type.start_with?("image/")
    return { error: "ファイルサイズは5MB以下にしてください" } if file.size > 5.megabytes

    # アップロードタイプに応じたファイル名と拡張子の生成
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    extension = upload_type == "content" ? "webp" : "jpg"
    filename = "#{timestamp}_#{SecureRandom.hex(8)}.#{extension}"

    if Rails.env.production?
      upload_to_gcs(file, filename, upload_type)
    else
      upload_to_local(file, filename, upload_type)
    end
  end

  private

  def self.upload_to_gcs(file, filename, upload_type)
    require "google/cloud/storage"
    require "image_processing/vips"

    # アップロードタイプに応じた拡張子の取得
    extension = filename.split(".").last
    temp_file = Tempfile.new([ "resized", ".#{extension}" ])

    begin
      # アップロードタイプに応じた画像処理
      processed_image = ImageProcessing::Vips.source(file.tempfile)

      if upload_type == "content"
        # 記事本文用: 最大2000px、WebP形式
        processed_image = processed_image
          .resize_to_limit(2000, 2000)
          .convert("webp")
          .saver(quality: 80)
        content_type = "image/webp"
      else
        # サムネイル用: OGサイズ（1200x630）、JPEG形式
        processed_image = processed_image
          .resize_to_fill(1200, 630, crop: :attention)
          .convert("jpeg")
          .saver(quality: 85)
        content_type = "image/jpeg"
      end

      processed_image.call(destination: temp_file.path)

      # GCSの設定
      storage = Google::Cloud::Storage.new(
        project_id: Rails.application.credentials.dig(:gcp, :project_id),
        credentials: Rails.application.credentials.dig(:gcp, :credentials)
      )

      bucket = storage.bucket(Rails.application.credentials.dig(:gcp, :bucket))

      # リサイズされたファイルをGCSにアップロード
      blob = bucket.create_file(
        temp_file.path,
        "images/#{filename}",
        content_type: content_type
      )

      # 公開アクセス可能にする
      blob.acl.public_read!

      # 公開URLを返す
      image_url = blob.public_url

      {
        url: image_url,
        markdown: "![画像](#{image_url})"
      }
    rescue => e
      Rails.logger.error "GCS upload error: #{e.message}"
      { error: "アップロードに失敗しました" }
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def self.upload_to_local(file, filename, upload_type)
    require "image_processing/vips"

    # ローカル保存（開発環境用）
    upload_dir = Rails.root.join("public", "uploads", "images")
    FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)

    file_path = upload_dir.join(filename)

    # アップロードタイプに応じた画像処理
    processed_image = ImageProcessing::Vips.source(file.tempfile)

    if upload_type == "content"
      # 記事本文用: 最大2000px、WebP形式
      processed_image
        .resize_to_limit(2000, 2000)
        .convert("webp")
        .saver(quality: 80)
        .call(destination: file_path)
    else
      # サムネイル用: OGサイズ（1200x630）、JPEG形式
      processed_image
        .resize_to_fill(1200, 630, crop: :attention)
        .convert("jpeg")
        .saver(quality: 85)
        .call(destination: file_path)
    end

    image_url = "/uploads/images/#{filename}"

    {
      url: image_url,
      markdown: "![画像](#{image_url})"
    }
  rescue => e
    Rails.logger.error "Local upload error: #{e.message}"
    { error: "アップロードに失敗しました" }
  end
end
