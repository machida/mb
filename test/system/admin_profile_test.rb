require "application_system_test_case"

class AdminProfileTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  test "admin can access profile edit page" do
    login_as_admin(@admin)
    
    # Navigate directly to profile edit page
    visit edit_admin_profile_path
    
    assert_selector ".spec--profile-edit-title", text: "プロフィール編集"
    assert_selector ".spec--email-input"
    assert_selector ".spec--user-id-input"
    assert_selector ".spec--password-change-link", text: "パスワードを変更"
  end

  test "admin can update email and user_id" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    
    find(".spec--email-input").fill_in with: "new@example.com"
    find(".spec--user-id-input").fill_in with: "newuser123"
    find(".spec--update-button").click
    
    assert_selector ".spec--toast-notification", text: "プロフィールを更新しました", wait: 10
    
    # Check if values are updated
    @admin.reload
    assert_equal "new@example.com", @admin.email
    assert_equal "newuser123", @admin.user_id
  end

  test "admin can navigate to password change page" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    
    click_link "パスワードを変更"
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec--password-edit-title", text: "パスワード変更"
  end

  test "admin sees validation errors for invalid email" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    
    # Try to set an invalid email format
    find(".spec--email-input").fill_in with: "invalid-email"
    find(".spec--update-button").click
    
    # Check if we stayed on the same page due to validation errors
    assert_current_path edit_admin_profile_path
    # Check for HTML5 validation or error message
    assert_selector ".spec--email-input:invalid", visible: false
  end


  test "admin can cancel profile edit" do
    login_as_admin(@admin)
    
    visit edit_admin_profile_path
    find(".spec--cancel-button").click
    
    assert_current_path admin_articles_path
  end
end