class Admin::DiagnosticsController < Admin::BaseController
  # 画像アップロード診断エンドポイント
  def image_upload_check
    diagnostics = {
      environment: Rails.env,
      vips_available: vips_check,
      gcs_configured: gcs_check,
      timestamp: Time.current
    }

    render json: diagnostics
  end

  private

  def vips_check
    ImageUploadService.vips_working?
  rescue => e
    { status: "error", message: e.message }
  end

  def gcs_check
    if Rails.env.production?
      {
        project_id: Rails.application.credentials.dig(:gcp, :project_id).present?,
        bucket: Rails.application.credentials.dig(:gcp, :bucket).present?,
        credentials: Rails.application.credentials.dig(:gcp, :credentials).present?
      }
    else
      { status: "development", message: "GCS not required in development" }
    end
  end
end
