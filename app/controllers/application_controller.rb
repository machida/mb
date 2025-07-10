class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  layout 'public'

  private

  def current_admin
    @current_admin ||= Admin.find(session[:admin_id]) if session[:admin_id]
  end

  def current_user_signed_in?
    current_admin.present?
  end

  def require_admin
    redirect_to admin_login_path unless current_user_signed_in?
  end

  helper_method :current_user_signed_in?, :current_admin
end
