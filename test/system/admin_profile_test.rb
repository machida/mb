require "application_system_test_case"

class AdminProfileTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def login_as_admin
    visit admin_login_path
    find(".spec-email-input").fill_in with: @admin.email
    find(".spec-password-input").fill_in with: "password123"
    find(".spec-login-button").click
  end

  test "admin can access profile edit page" do
    login_as_admin
    
    visit admin_articles_path
    assert_selector ".js-dropdown-button"
    find(".js-dropdown-button").click
    find(".spec-profile-edit-link").click
    
    assert_selector ".spec-profile-edit-title", text: "プロフィール編集"
    assert_selector ".spec-email-input"
    assert_selector ".spec-user-id-input"
    assert_selector ".spec-password-change-link", text: "パスワードを変更"
  end

  test "admin can update email and user_id" do
    login_as_admin
    
    visit edit_admin_profile_path
    
    find(".spec-email-input").fill_in with: "new@example.com"
    find(".spec-user-id-input").fill_in with: "newuser123"
    find(".spec-update-button").click
    
    assert_selector ".toast-notification", text: "プロフィールを更新しました"
    
    # Check if values are updated
    @admin.reload
    assert_equal "new@example.com", @admin.email
    assert_equal "newuser123", @admin.user_id
  end

  test "admin can navigate to password change page" do
    login_as_admin
    
    visit edit_admin_profile_path
    
    click_link "パスワードを変更"
    
    assert_current_path edit_admin_password_path
    assert_selector ".spec-password-edit-title", text: "パスワード変更"
  end

  test "admin sees validation errors for invalid input" do
    login_as_admin
    
    visit edit_admin_profile_path
    
    find(".spec-email-input").fill_in with: ""
    find(".spec-user-id-input").fill_in with: ""
    find(".spec-update-button").click
    
    assert_selector ".spec-error-messages"
    assert_text "Email can't be blank"
    assert_text "User can't be blank"
  end


  test "admin can cancel profile edit" do
    login_as_admin
    
    visit edit_admin_profile_path
    find(".spec-cancel-button").click
    
    assert_current_path admin_articles_path
  end
end