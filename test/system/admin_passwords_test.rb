require "application_system_test_case"

class AdminPasswordsTest < ApplicationSystemTestCase
  def setup
    Admin.destroy_all
    @admin = create_admin
  end

  test "should show password change page" do
    login_as_admin(@admin)
    
    # Navigate directly to profile edit page
    visit edit_admin_profile_path
    find(".spec--password-change-link").click
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec--password-edit-title", text: "パスワード変更"
    assert_selector ".spec--password-input"
    assert_selector ".spec--password-confirmation-input"
  end

  test "should change password successfully" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    find(".spec--password-change-link").click
    
    find(".spec--password-input").fill_in with: "newpassword456"
    find(".spec--password-confirmation-input").fill_in with: "newpassword456"
    
    find(".spec--password-change-button").click
    
    assert_current_path edit_admin_profile_path
    assert_text "パスワードが正常に更新されました"
    
    # Verify password was changed by checking the admin was actually updated
    @admin.reload
    assert @admin.authenticate("newpassword456")
  end

  test "should show error for short password" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    find(".spec--password-change-link").click
    
    find(".spec--password-input").fill_in with: "123"
    find(".spec--password-confirmation-input").fill_in with: "123"
    
    find(".spec--password-change-button").click
    
    # Check if we stayed on the same page due to validation errors
    assert_current_path edit_admin_password_path
    # Look for any error indication - could be validation messages or form errors
    assert_selector ".spec--error-messages", text: "Password is too short"
  end

  test "should show error for mismatched passwords" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    find(".spec--password-change-link").click
    
    find(".spec--password-input").fill_in with: "newpassword456"
    find(".spec--password-confirmation-input").fill_in with: "different456"
    
    find(".spec--password-change-button").click
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec--error-messages"
  end

  test "should navigate from profile to password change" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    find(".spec--password-change-link").click
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec--password-edit-title", text: "パスワード変更"
  end

  test "should cancel and return to profile" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    find(".spec--password-change-link").click
    
    find(".spec--cancel-button").click
    
    assert_current_path edit_admin_profile_path
  end

  test "should redirect to login when not authenticated" do
    visit edit_admin_password_path
    assert_current_path admin_login_path
  end

  # Common helper methods moved to ApplicationSystemTestCase
end