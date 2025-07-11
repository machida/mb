require "test_helper"

class Admin::PasswordsControllerTest < ActionDispatch::IntegrationTest
  def setup
    Admin.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def login_as_admin
    post admin_login_path, params: { email: @admin.email, password: "password123" }
  end

  test "should redirect to login when not authenticated" do
    get edit_admin_password_path
    assert_redirected_to admin_login_path
  end

  test "should get edit when authenticated" do
    login_as_admin
    get edit_admin_password_path
    assert_response :success
    assert_select ".spec-password-edit-title", "パスワード変更"
    assert_select ".spec-password-input"
    assert_select ".spec-password-confirmation-input"
  end

  test "should update password with valid data" do
    login_as_admin
    
    patch admin_password_path, params: {
      admin: {
        password: "newpassword456",
        password_confirmation: "newpassword456"
      }
    }
    
    @admin.reload
    assert @admin.authenticate("newpassword456")
    assert_redirected_to edit_admin_profile_path
    follow_redirect!
    assert_match "パスワードが正常に更新されました", response.body
  end

  test "should not update with blank password" do
    login_as_admin
    
    patch admin_password_path, params: {
      admin: {
        password: "",
        password_confirmation: ""
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".spec-error-messages"
    
    # Password should not have changed
    @admin.reload
    assert @admin.authenticate("password123")
  end

  test "should not update with short password" do
    login_as_admin
    
    patch admin_password_path, params: {
      admin: {
        password: "short",
        password_confirmation: "short"
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".spec-error-messages"
  end

  test "should not update with mismatched confirmation" do
    login_as_admin
    
    patch admin_password_path, params: {
      admin: {
        password: "newpassword456",
        password_confirmation: "different456"
      }
    }
    
    assert_response :unprocessable_entity
    assert_select ".spec-error-messages"
  end

  test "should not allow access without login" do
    patch admin_password_path, params: {
      admin: {
        password: "newpassword456",
        password_confirmation: "newpassword456"
      }
    }
    
    assert_redirected_to admin_login_path
  end
end