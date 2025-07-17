# test/support/authentication_helpers.rb
module AuthenticationHelpers
  extend ActiveSupport::Concern
  
  included do
    include Rails.application.routes.url_helpers
  end
  
  # Integration test authentication helper
  def login_as_admin(admin = nil)
    admin ||= create_admin
    config = TestConfiguration.test_data_config
    post admin_login_path, params: { 
      email: admin.email, 
      password: config[:admin_password]
    }
    admin
  end

  # Logout helper
  def logout_admin
    delete admin_logout_path
  end

  # Check if admin is logged in
  def admin_logged_in?
    session[:admin_id].present?
  end
end