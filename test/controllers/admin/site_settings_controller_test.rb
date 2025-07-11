require "test_helper"

class Admin::SiteSettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    Admin.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
    
    post admin_login_path, params: { email: @admin.email, password: "password123" }
  end

  test "should show site settings page" do
    get admin_site_settings_path
    assert_response :success
    assert_select ".spec-site-settings-title", "サイト設定"
    assert_select ".spec-site-title-input"
    assert_select ".spec-default-og-image-input"
    assert_select ".spec-top-page-description-input"
    assert_select ".spec-copyright-input"
    # Check for thumbnail upload components
    assert_select "div[data-controller='thumbnail-upload']"
  end

  test "should update site settings" do
    patch admin_site_settings_path, params: {
      site_settings: {
        site_title: "新しいブログタイトル",
        default_og_image: "https://example.com/new-image.jpg",
        top_page_description: "新しい説明文です",
        copyright: "© 2025 新しいブログ. All rights reserved."
      }
    }
    
    assert_redirected_to admin_site_settings_path
    follow_redirect!
    assert_match "サイト設定を更新しました", response.body
    
    # 設定値が更新されているか確認
    assert_equal "新しいブログタイトル", SiteSetting.site_title
    assert_equal "https://example.com/new-image.jpg", SiteSetting.default_og_image
    assert_equal "新しい説明文です", SiteSetting.top_page_description
    assert_equal "© 2025 新しいブログ. All rights reserved.", SiteSetting.copyright
  end

  test "should not allow access without login" do
    delete admin_logout_path
    
    get admin_site_settings_path
    assert_redirected_to admin_login_path
    
    patch admin_site_settings_path, params: {
      site_settings: {
        site_title: "Test"
      }
    }
    assert_redirected_to admin_login_path
  end
end