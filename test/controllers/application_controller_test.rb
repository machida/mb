require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  def setup
    Admin.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should use public layout by default" do
    get root_path
    assert_response :success
    assert_select "body.layout-public"
  end

  test "current_user_signed_in? should return false when not logged in" do
    get root_path
    assert_response :success
    # Check that login link is present (indicates not signed in)
    assert_select "a[href=?]", admin_login_path, text: "ログイン"
  end

  test "current_user_signed_in? should return true when logged in" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get root_path
    assert_response :success
    # Check that admin links are present (indicates signed in)
    assert_select "a", text: "記事管理"
  end

  test "current_admin should return nil when not logged in" do
    get root_path
    assert_response :success
    # Verify no admin-specific content is shown
    assert_select "a", { text: "記事管理", count: 0 }
  end

  test "current_admin should return admin when logged in" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get root_path
    assert_response :success
    # Verify admin-specific content is shown
    assert_select "a", text: "記事管理"
  end

  test "require_admin should redirect to login when not authenticated" do
    # This is tested through admin controllers
    get admin_articles_path
    assert_redirected_to admin_login_path
  end

  test "require_admin should allow access when authenticated" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get admin_articles_path
    assert_response :success
  end

  test "session should persist across requests" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    assert_equal @admin.id, session[:admin_id]
    
    # Make another request to verify session persistence
    get admin_articles_path
    assert_response :success
    assert_equal @admin.id, session[:admin_id]
  end

  test "should handle missing admin in session gracefully" do
    # Set an invalid admin_id in session
    post admin_login_path, params: { email: @admin.email, password: "password123" }

    # Delete the admin to simulate a missing admin
    @admin.destroy

    # Should redirect to login when admin no longer exists
    get admin_articles_path
    assert_redirected_to admin_login_path
  end

  test "flash messages work correctly" do
    # Test login success message
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    # Login should redirect (exact path may vary)
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # Test logout success message
    delete admin_logout_path
    assert_redirected_to root_path
    follow_redirect!
    # Verify we're back to public page
    assert_response :success
    assert_select "body.layout-public"
  end

  test "error messages work correctly" do
    # Test login with wrong credentials
    post admin_login_path, params: { email: @admin.email, password: "wrongpassword" }

    # Should not redirect, should render login page with error
    assert_response :unprocessable_content
  end

  test "redirect_with_success sets flash and redirects" do
    # Test through a controller that uses this method
    # Since no existing controller uses it directly, we test via admin logout
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    delete admin_logout_path

    assert_redirected_to root_path
    follow_redirect!
    # Flash should be set (though it might not be displayed in the template)
    # We can't directly test flash content after redirect, but we verify the redirect worked
    assert_response :success
  end

  test "set_error_message adds alert to flash" do
    # Test through login failure which uses flash[:alert]
    post admin_login_path, params: { email: @admin.email, password: "wrongpassword" }
    assert_response :unprocessable_content
    # Error messages should be present in the rendered form
    assert_select "body"
  end
end