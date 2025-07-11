require "application_system_test_case"

class AdminSiteSettingsTest < ApplicationSystemTestCase
  def setup
    Admin.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should show site settings page" do
    login_as_admin
    visit admin_site_settings_path
    
    assert_selector ".spec-site-settings-title", text: "サイト設定"
    assert_selector ".spec-site-title-input"
    assert_selector ".spec-default-og-image-input"
    assert_selector ".spec-top-page-description-input"
    assert_selector ".spec-copyright-input"
  end

  test "should update site settings" do
    login_as_admin
    visit admin_site_settings_path
    
    find(".spec-site-title-input").fill_in with: "新しいブログタイトル"
    find(".spec-top-page-description-input").fill_in with: "新しい説明文です"
    find(".spec-copyright-input").fill_in with: "新しいブログ"
    
    click_button "設定を保存"
    
    assert_current_path admin_site_settings_path
    assert_text "サイト設定を更新しました"
    
    # Check values were saved
    assert_equal "新しいブログタイトル", SiteSetting.site_title
    assert_equal "新しい説明文です", SiteSetting.top_page_description
    assert_equal "新しいブログ", SiteSetting.copyright
  end

  test "should show current settings" do
    # Set some test settings
    SiteSetting.set("site_title", "テストタイトル")
    SiteSetting.set("top_page_description", "テスト説明")
    SiteSetting.set("copyright", "テスト著作者")
    
    login_as_admin
    visit admin_site_settings_path
    
    assert_field "site_settings[site_title]", with: "テストタイトル"
    assert_field "site_settings[top_page_description]", with: "テスト説明"
    assert_field "site_settings[copyright]", with: "テスト著作者"
  end

  test "should redirect to login when not authenticated" do
    visit admin_site_settings_path
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