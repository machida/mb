class Admin::SiteSettingsController < Admin::BaseController
  def show
    @settings = {
      default_og_image: SiteSetting.default_og_image,
      top_page_description: SiteSetting.top_page_description,
      author_display_enabled: SiteSetting.get("author_display_enabled", "true"),
      openai_api_key: SiteSetting.openai_api_key
    }
  end

  def update
    begin
      settings_params.each do |key, value|
        if value.present?
          SiteSetting.set(key, value)
        elsif key == "default_og_image" && value.blank?
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
      :default_og_image,
      :top_page_description,
      :author_display_enabled,
      :openai_api_key
    )
  end
end
