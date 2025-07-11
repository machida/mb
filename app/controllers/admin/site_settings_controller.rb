class Admin::SiteSettingsController < Admin::BaseController
  def show
    @settings = {
      site_title: SiteSetting.site_title,
      default_og_image: SiteSetting.default_og_image,
      top_page_description: SiteSetting.top_page_description,
      copyright: SiteSetting.copyright
    }
  end

  def update
    settings_params.each do |key, value|
      if value.present?
        SiteSetting.set(key, value)
      elsif key == "default_og_image" && value.blank?
        # デフォルトOG画像が削除された場合は空文字を設定
        SiteSetting.set(key, "")
      end
    end

    redirect_to admin_site_settings_path, notice: "サイト設定を更新しました"
  end

  def upload_image
    if params[:image].present?
      # サイト設定用の画像アップロード（OGサイズ、JPEG形式）
      result = ImageUploadService.upload(params[:image], upload_type: "thumbnail")

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
    params.require(:site_settings).permit(:site_title, :default_og_image, :top_page_description, :copyright)
  end
end
