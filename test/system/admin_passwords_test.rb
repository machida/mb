require "application_system_test_case"

class AdminPasswordsTest < ApplicationSystemTestCase
  def setup
    Admin.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should show password change page" do
    login_as_admin
    
    # Navigate through admin interface to password page
    visit admin_articles_path
    find(".js-dropdown-button").click
    find(".spec-profile-edit-link").click
    click_link "パスワードを変更"
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec-password-edit-title", text: "パスワード変更"
    assert_selector ".spec-password-input"
    assert_selector ".spec-password-confirmation-input"
  end

  test "should change password successfully" do
    login_as_admin
    
    visit admin_articles_path
    find(".js-dropdown-button").click
    find(".spec-profile-edit-link").click
    click_link "パスワードを変更"
    
    find(".spec-password-input").fill_in with: "newpassword456"
    find(".spec-password-confirmation-input").fill_in with: "newpassword456"
    
    click_button "パスワードを変更"
    
    assert_current_path edit_admin_profile_path
    assert_text "パスワードを変更しました"
    
    # Verify password was changed by logging out and back in
    find(".js-dropdown-button").click
    click_on "サインアウト"
    
    visit admin_login_path
    find(".spec-email-input").fill_in with: @admin.email
    find(".spec-password-input").fill_in with: "newpassword456"
    find(".spec-login-button").click
    
    assert_current_path root_path
    assert_text "ログインしました"
  end

  test "should show error for blank password" do
    login_as_admin
    
    visit admin_articles_path
    find(".js-dropdown-button").click
    find(".spec-profile-edit-link").click
    click_link "パスワードを変更"
    
    find(".spec-password-input").fill_in with: ""
    find(".spec-password-confirmation-input").fill_in with: ""
    
    click_button "パスワードを変更"
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec-error-messages"
  end

  test "should show error for mismatched passwords" do
    login_as_admin
    
    visit admin_articles_path
    find(".js-dropdown-button").click
    find(".spec-profile-edit-link").click
    click_link "パスワードを変更"
    
    find(".spec-password-input").fill_in with: "newpassword456"
    find(".spec-password-confirmation-input").fill_in with: "different456"
    
    click_button "パスワードを変更"
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec-error-messages"
  end

  test "should navigate from profile to password change" do
    login_as_admin
    
    visit admin_articles_path
    find(".js-dropdown-button").click
    find(".spec-profile-edit-link").click
    
    click_link "パスワードを変更"
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec-password-edit-title", text: "パスワード変更"
  end

  test "should cancel and return to profile" do
    login_as_admin
    
    visit admin_articles_path
    find(".js-dropdown-button").click
    find(".spec-profile-edit-link").click
    click_link "パスワードを変更"
    
    click_link "キャンセル"
    
    assert_current_path edit_admin_profile_path
  end

  test "should redirect to login when not authenticated" do
    visit edit_admin_password_path
    assert_current_path admin_login_path
  end

  private

  def login_as_admin
    visit admin_login_path
    find(".spec-email-input").fill_in with: @admin.email
    find(".spec-password-input").fill_in with: "password123"
    find(".spec-login-button").click
  end
end