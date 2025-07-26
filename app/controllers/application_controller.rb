class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # CSRF protection
  protect_from_forgery with: :exception

  layout "public"

  protected

  def set_success_message(message)
    flash[:notice] = message
  end

  def set_error_message(message)
    flash[:alert] = message
  end

  def redirect_with_success(path, message)
    set_success_message(message)
    redirect_to path
  end

  def redirect_with_error(path, message)
    set_error_message(message)
    redirect_to path
  end

  private

  def current_admin
    @current_admin ||= Admin.find(session[:admin_id]) if session[:admin_id]
  rescue ActiveRecord::RecordNotFound
    session[:admin_id] = nil
    nil
  end

  def current_user_signed_in?
    current_admin.present?
  end

  def require_admin
    redirect_to admin_login_path unless current_user_signed_in?
  end

  helper_method :current_user_signed_in?, :current_admin
end
