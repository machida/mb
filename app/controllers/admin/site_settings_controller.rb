class Admin::SiteSettingsController < Admin::BaseController
  def show
    @settings = {
      site_title: SiteSetting.site_title,
      default_og_image: SiteSetting.default_og_image,
      hero_background_image: SiteSetting.hero_background_image,
      hero_text_color: SiteSetting.hero_text_color,
      top_page_description: SiteSetting.top_page_description,
      copyright: SiteSetting.copyright,
      author_display_enabled: SiteSetting.get("author_display_enabled", "true"),
      openai_api_key: SiteSetting.openai_api_key
    }
  end

  def update
    begin
      settings_params.each do |key, value|
        if key == "copyright"
          # 著作権者名は空白も含めて常に更新を許可（trimも実行）
          # また、フル著作権テキスト（© 年 名前. All rights reserved.）から名前部分だけを抽出
          cleaned_value = extract_copyright_name(value.to_s.strip)
          SiteSetting.set(key, cleaned_value)
        elsif key == "hero_text_color"
          allowed = %w[white black]
          SiteSetting.set(key, allowed.include?(value) ? value : "white")
        elsif value.present?
          SiteSetting.set(key, value)
        elsif %w[default_og_image hero_background_image].include?(key) && value.blank?
          # デフォルトOG画像が削除された場合は空文字を設定
          SiteSetting.set(key, "")
        end
      end
      redirect_to admin_site_settings_path, notice: "サイト設定を更新しました"
    rescue => e
      Rails.logger.error "Site settings update error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to admin_site_settings_path, alert: "設定の更新に失敗しました: #{e.message}"
    end
  end

  def upload_image
    if params[:image].present?
      # サイト設定用の画像アップロード
      upload_type = params[:upload_type].presence || "thumbnail"
      result = ImageUploadService.upload(params[:image], upload_type: upload_type)

      if result[:error]
        render json: { error: result[:error] }, status: 422
      else
        render json: result
      end
    else
      render json: { error: "画像ファイルが選択されていません" }, status: 422
    end
  rescue => e
    Rails.logger.error "Site settings image upload error: #{e.message}"
    render json: { error: "アップロードに失敗しました" }, status: 500
  end

  private

  def settings_params
    params.require(:site_settings).permit(
      :site_title,
      :default_og_image,
      :hero_background_image,
      :hero_text_color,
      :top_page_description,
      :copyright,
      :author_display_enabled,
      :openai_api_key
    )
  end

  # フル著作権テキストから著作権者名だけを抽出
  # 例: "© 2025 会社名. All rights reserved." → "会社名"
  def extract_copyright_name(value)
    return value if value.blank?

    # © 年 名前. All rights reserved. の形式をチェック
    if value.match(/^©\s*\d{4}\s+(.+?)\.\s*All rights reserved\.?$/i)
      # マッチした場合は名前部分を抽出
      $1.strip
    else
      # マッチしない場合はそのまま返す（通常の名前入力）
      value
    end
  end
end
