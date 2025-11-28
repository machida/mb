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

      case upload_type
      when "content"
        # 記事本文用: 最大2000px、WebP形式
        processed_image = processed_image
          .resize_to_limit(2000, 2000)
          .convert("webp")
          .saver(quality: 80)
        content_type = "image/webp"
      when "hero"
        # ヒーロー背景用: ワイドサイズ、JPEG形式
        processed_image = processed_image
          .resize_to_fill(1920, 1080, crop: :attention)
          .convert("jpeg")
          .saver(quality: 85)
        content_type = "image/jpeg"
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

      # リサイズされたファイルをGCSにアップロード
      blob = bucket.create_file(
        temp_file.path,
        "images/#{filename}",
        content_type: content_type
      )

      # 公開URLを返す
      # Note: バケットは"allUsers"に対してStorage Object Viewerロールを付与する必要があります
      # GCPコンソール > Storage > バケット > Permissions で設定
      image_url = blob.public_url

      {
        url: image_url,
        markdown: "![画像](#{image_url})"
      }
    rescue => e
      Rails.logger.error "GCS upload error: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { error: "アップロードに失敗しました: #{e.message}" }
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

    file_path = upload_dir.join(filename).to_s

    # アップロードタイプに応じた画像処理
    # tempfileまたはファイルから読み込み可能なパスを取得
    if file.respond_to?(:tempfile)
      if file.tempfile.respond_to?(:path)
        source_path = file.tempfile.path
      else
        # StringIOの場合は一時ファイルに書き出す
        temp_source = Tempfile.new([ "upload_source", ".tmp" ])
        temp_source.binmode
        file.tempfile.rewind
        temp_source.write(file.tempfile.read)
        temp_source.close
        source_path = temp_source.path
      end
    else
      source_path = file.path
    end

    processed_image = ImageProcessing::Vips.source(source_path)

    case upload_type
    when "content"
      # 記事本文用: 最大2000px、WebP形式
      processed_image
        .resize_to_limit(2000, 2000)
        .convert("webp")
        .saver(quality: 80)
        .call(destination: file_path)
    when "hero"
      processed_image
        .resize_to_fill(1920, 1080, crop: :attention)
        .convert("jpeg")
        .saver(quality: 85)
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
    Rails.logger.error "Image processing error: #{e.message}"
    { error: "画像処理に失敗しました" }
  ensure
    # StringIOから作成した一時ファイルをクリーンアップ
    temp_source&.unlink if defined?(temp_source) && temp_source.respond_to?(:unlink)
  end

  # VIPSの動作確認テスト
  def self.vips_working?
    require "image_processing/vips"

    # VIPSで1x1ピクセルの黒い画像を作成
    image = Vips::Image.black(1, 1)

    # テスト用一時ファイルを作成
    source_file = Tempfile.new([ "vips_source", ".jpg" ])
    result_file = Tempfile.new([ "vips_result", ".webp" ])

    source_file.close
    result_file.close

    # 元画像を保存
    image.write_to_file(source_file.path)

    # VIPS処理テスト: リサイズとフォーマット変換
    ImageProcessing::Vips
      .source(source_file.path)
      .resize_to_limit(10, 10)
      .convert("webp")
      .call(destination: result_file.path)

    # 結果ファイルが存在し、サイズが0以上であることを確認
    File.exist?(result_file.path) && File.size(result_file.path) > 0
  rescue => e
    Rails.logger.error "VIPS test failed: #{e.message}"
    false
  ensure
    source_file&.unlink
    result_file&.unlink
  end
end
