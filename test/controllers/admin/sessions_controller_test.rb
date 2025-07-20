require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = admins(:admin)
  end

  test "should get login page" do
    get admin_login_path
    assert_response :success
    assert_select ".spec--login-title", "管理者ログイン"
    assert_select "form[action=?]", admin_login_path
  end

  test "should login with valid credentials" do
    post admin_login_path, params: {
      email: @admin.email,
      password: "password123"
    }
    
    assert_redirected_to root_path
    assert_equal @admin.id, session[:admin_id]
    follow_redirect!
    assert_select ".spec--toast-notification", text: /ログインしました/
  end

  test "should not login with invalid email" do
    post admin_login_path, params: {
      email: "wrong@example.com",
      password: "password123"
    }
    
    assert_response :unprocessable_entity
    assert_nil session[:admin_id]
    assert_select ".a--card.is-danger", text: /メールアドレスまたはパスワードが間違っています/
  end

  test "should not login with invalid password" do
    post admin_login_path, params: {
      email: @admin.email,
      password: "wrongpassword"
    }
    
    assert_response :unprocessable_entity
    assert_nil session[:admin_id]
    assert_select ".a--card.is-danger", text: /メールアドレスまたはパスワードが間違っています/
  end

  test "should logout" do
    # First login
    post admin_login_path, params: {
      email: @admin.email,
      password: "password123"
    }
    assert_equal @admin.id, session[:admin_id]
    
    # Then logout
    delete admin_logout_path
    assert_redirected_to root_path
    assert_nil session[:admin_id]
    follow_redirect!
    assert_select ".spec--toast-notification", text: /ログアウトしました/
  end
end
