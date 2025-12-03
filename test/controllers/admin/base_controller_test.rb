require "test_helper"

class Admin::BaseControllerTest < ActionDispatch::IntegrationTest
  def setup
    Admin.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # Admin::BaseController is abstract, so we test it through a concrete subclass
  test "should redirect to login when not authenticated" do
    # Test through ArticlesController which inherits from BaseController
    get admin_articles_path
    assert_redirected_to admin_login_path
  end

  test "should allow access when authenticated" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get admin_articles_path
    assert_response :success
  end

  test "should use admin layout" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get admin_articles_path
    assert_response :success
    # Check that admin layout is being used
    assert_select "header"
    assert_select "main"
  end

  test "should clear session on logout" do
    # Login first
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    assert_equal @admin.id, session[:admin_id]
    
    # Logout
    delete admin_logout_path
    assert_nil session[:admin_id]
    assert_redirected_to root_path
  end

  test "should maintain session across requests when logged in" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }

    # Make multiple requests to verify session persistence
    get admin_articles_path
    assert_response :success
    assert_equal @admin.id, session[:admin_id]

    get admin_site_settings_path
    assert_response :success
    assert_equal @admin.id, session[:admin_id]
  end

  test "should set robots meta header on admin pages" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }

    get admin_articles_path
    assert_equal "noindex, nofollow, noarchive, nosnippet, nocache",
                 response.headers["X-Robots-Tag"]
  end
end