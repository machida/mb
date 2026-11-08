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

  # Rotate the session and bind it to the administrator's current password.
  def start_admin_session(admin)
    reset_session
    session[:admin_id] = admin.id
    session[:admin_credential] = admin.session_credential
  end

  # Reject stale cookies and accounts whose credential has been removed.
  def current_admin
    return @current_admin if defined?(@current_admin)

    admin = Admin.find_by(id: session[:admin_id]) if session[:admin_id]
    if admin&.password_digest.present? && ActiveSupport::SecurityUtils.secure_compare(
      session[:admin_credential].to_s, admin.session_credential
    )
      @current_admin = admin
    else
      reset_session if session[:admin_id]
      @current_admin = nil
    end
  end

  def current_user_signed_in?
    current_admin.present?
  end

  def require_admin
    redirect_to admin_login_path unless current_user_signed_in?
  end

  helper_method :current_user_signed_in?, :current_admin
end
