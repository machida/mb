class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :require_admin
  before_action :set_robots_header

  private

  def set_robots_header
    # 管理画面は検索エンジンにインデックスされないよう HTTP ヘッダーでも制御
    response.headers["X-Robots-Tag"] = "noindex, nofollow, noarchive, nosnippet, nocache"
  end

  protected

  def set_success_message(message)
    flash[:notice] = message
  end

  def set_error_message(message)
    flash[:alert] = message
  end

  def handle_validation_errors(object)
    if object.errors.any?
      set_error_message(object.errors.full_messages.join(", "))
      return false
    end
    true
  end

  def render_with_errors(template, object, status = :unprocessable_content)
    handle_validation_errors(object)
    render template, status: status
  end
end
