module AdminTestHelper
  # Admin authentication helper methods
  def login_as_admin(admin = nil)
    admin ||= create_test_admin
    post admin_login_path, params: {
      email: admin.email,
      password: TestConfig::TEST_ADMIN_PASSWORD
    }
    admin
  end

  def logout_admin
    delete admin_logout_path if session[:admin_id]
  end

  def create_test_admin(attributes = {})
    default_attributes = {
      email: TestConfig::TEST_ADMIN_EMAIL,
      user_id: TestConfig::TEST_ADMIN_USER_ID,
      password: TestConfig::TEST_ADMIN_PASSWORD,
      password_confirmation: TestConfig::TEST_ADMIN_PASSWORD
    }
    Admin.create!(default_attributes.merge(attributes))
  end

  def create_other_admin(attributes = {})
    default_attributes = {
      user_id: "other_admin",
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
    Admin.create!(default_attributes.merge(attributes))
  end

  # Common admin test assertions
  def assert_admin_authentication_required(path, method = :get, params = {})
    case method
    when :get
      get path, params: params
    when :post
      post path, params: params
    when :patch
      patch path, params: params
    when :delete
      delete path, params: params
    end
    
    assert_redirected_to admin_login_path
  end

  def assert_toast_message(message_text)
    assert_select ".spec--toast-notification", text: /#{Regexp.escape(message_text)}/
  end

  def assert_admin_item_present(admin)
    assert_select ".spec--admin-user-id", text: admin.user_id
    assert_select ".spec--admin-email", text: admin.email
  end

  def assert_admin_form_fields
    assert_select ".spec--user-id-input"
    assert_select ".spec--email-input"
    assert_select ".spec--password-input"
    assert_select ".spec--password-confirmation-input"
  end
end