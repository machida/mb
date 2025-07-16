require "application_playwright_test_case"

class AdminPasswordsPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    Admin.destroy_all
    @admin = create_admin
  end

  test "should show password change page" do
    login_as_admin(@admin)
    
    # Navigate directly to profile edit page
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    @page.click(".spec--password-change-link")
    
    @page.wait_for_url(/.*\/admin\/password\/edit/)
    
    # Check page elements
    title_element = @page.query_selector(".spec--password-edit-title")
    assert title_element, "Password edit title should exist"
    assert_equal "パスワード変更", title_element.inner_text
    
    assert @page.query_selector(".spec--password-input"), "Password input should exist"
    assert @page.query_selector(".spec--password-confirmation-input"), "Password confirmation input should exist"
  end

  test "should change password successfully" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    @page.click(".spec--password-change-link")
    
    @page.fill(".spec--password-input", "newpassword456")
    @page.fill(".spec--password-confirmation-input", "newpassword456")
    
    @page.click(".spec--password-change-button")
    
    @page.wait_for_url(/.*\/admin\/profile\/edit/)
    
    # Check for success message
    page_text = @page.inner_text("body")
    assert_includes page_text, "パスワードが正常に更新されました"
    
    # Verify password was changed by checking the admin was actually updated
    @admin.reload
    assert @admin.authenticate("newpassword456")
  end

  test "should show error for short password" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    @page.click(".spec--password-change-link")
    
    @page.fill(".spec--password-input", "123")
    @page.fill(".spec--password-confirmation-input", "123")
    
    @page.click(".spec--password-change-button")
    
    @page.wait_for_load_state('networkidle')
    
    # Check if we stayed on the same page due to validation errors
    assert_match /\/admin\/password\/edit/, @page.url
    
    # Look for error message
    error_element = @page.query_selector(".spec--error-messages")
    assert error_element, "Error messages should exist"
    assert_includes error_element.inner_text, "Password is too short"
  end

  test "should show error for mismatched passwords" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    @page.click(".spec--password-change-link")
    
    @page.fill(".spec--password-input", "newpassword456")
    @page.fill(".spec--password-confirmation-input", "different456")
    
    @page.click(".spec--password-change-button")
    
    @page.wait_for_load_state('networkidle')
    
    # Check if we stayed on the same page due to validation errors
    assert_match /\/admin\/password\/edit/, @page.url
    
    # Look for error messages element
    error_element = @page.query_selector(".spec--error-messages")
    assert error_element, "Error messages should exist"
  end

  test "should navigate from profile to password change" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    @page.click(".spec--password-change-link")
    
    @page.wait_for_url(/.*\/admin\/password\/edit/)
    
    title_element = @page.query_selector(".spec--password-edit-title")
    assert title_element, "Password edit title should exist"
    assert_equal "パスワード変更", title_element.inner_text
  end

  test "should cancel and return to profile" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    @page.click(".spec--password-change-link")
    
    @page.click(".spec--cancel-button")
    
    @page.wait_for_url(/.*\/admin\/profile\/edit/)
    assert_match /\/admin\/profile\/edit/, @page.url
  end

  test "should redirect to login when not authenticated" do
    @page.goto("http://localhost:#{@server_port}/admin/password/edit")
    @page.wait_for_url(/.*\/admin\/login/)
    
    # Verify we're on the login page
    assert_match /\/admin\/login/, @page.url
  end
end