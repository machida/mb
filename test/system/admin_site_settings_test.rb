require "application_system_test_case"

class AdminSiteSettingsTest < ApplicationSystemTestCase
  def setup
    Admin.destroy_all
    @admin = create_admin
  end

  test "should show site settings page" do
    login_as_admin(@admin)
    
    # Navigate to admin area first
    visit admin_articles_path
    assert_current_path admin_articles_path
    
    visit admin_site_settings_path
    assert_current_path admin_site_settings_path
    
    assert_selector ".spec-site-settings-title", text: "サイト設定"
    assert_selector ".spec-site-title-input"
    assert_selector ".spec-default-og-image-input", visible: false
    assert_selector ".spec-top-page-description-input"
    assert_selector ".spec-copyright-input"
  end

  test "should update site settings" do
    login_as_admin(@admin)
    
    visit admin_articles_path
    visit admin_site_settings_path
    
    find(".spec-site-title-input").fill_in with: "新しいブログタイトル"
    find(".spec-top-page-description-input").fill_in with: "新しい説明文です"
    find(".spec-copyright-input").fill_in with: "新しいブログ"
    
    find(".spec-save-button").click
    
    assert_current_path admin_site_settings_path
    assert_selector ".spec-toast-notification", text: "サイト設定を更新しました"
    
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
    
    login_as_admin(@admin)
    
    visit admin_articles_path
    visit admin_site_settings_path
    
    assert_field "site_settings[site_title]", with: "テストタイトル"
    assert_field "site_settings[top_page_description]", with: "テスト説明"
    assert_field "site_settings[copyright]", with: "テスト著作者"
  end

  test "should redirect to login when not authenticated" do
    visit admin_site_settings_path
    assert_current_path admin_login_path
  end

  # Common helper methods moved to ApplicationSystemTestCase
end