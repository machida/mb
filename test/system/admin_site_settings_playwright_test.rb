require "application_playwright_test_case"

class AdminSiteSettingsPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    Admin.destroy_all
    @admin = create_admin
  end

  test "should show site settings page" do
    login_as_admin(@admin)
    
    # Navigate to admin area first
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.wait_for_url(/.*\/admin\/articles/)
    
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_url(/.*\/admin\/site-settings/)
    
    # Check page elements
    title_element = @page.query_selector(".spec--site-settings-title")
    assert title_element, "Site settings title should exist"
    assert_equal "サイト設定", title_element.inner_text
    
    assert @page.query_selector(".spec--site-title-input"), "Site title input should exist"
    
    # Check that default OG image input exists but is hidden
    og_image_input = @page.query_selector(".spec--default-og-image-input")
    assert og_image_input, "Default OG image input should exist"
    assert_equal false, og_image_input.visible?, "Default OG image input should be hidden"
    
    assert @page.query_selector(".spec--top-page-description-input"), "Top page description input should exist"
    assert @page.query_selector(".spec--copyright-input"), "Copyright input should exist"
  end

  test "should update site settings" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    
    # Fill in form fields
    @page.fill(".spec--site-title-input", "新しいブログタイトル")
    @page.fill(".spec--top-page-description-input", "新しい説明文です")
    @page.fill(".spec--copyright-input", "新しいブログ")
    
    # Submit form
    @page.click(".spec--save-button")
    
    # Wait for redirect and success message
    @page.wait_for_url(/.*\/admin\/site-settings/)
    
    # Wait for toast notification to appear
    toast_selector = ".spec--toast-notification"
    @page.wait_for_selector(toast_selector, timeout: 10000)
    
    toast_element = @page.query_selector(toast_selector)
    assert toast_element, "Toast notification should appear"
    assert_equal "サイト設定を更新しました", toast_element.inner_text
    
    # Wait for any async operations to complete
    @page.wait_for_load_state(state: 'networkidle')
    
    # Force cache clearing
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
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
    
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    
    # Check form field values
    site_title_input = @page.locator("input[name='site_settings[site_title]']")
    assert_equal "テストタイトル", site_title_input.input_value
    
    description_input = @page.locator("textarea[name='site_settings[top_page_description]']")
    assert_equal "テスト説明", description_input.input_value
    
    copyright_input = @page.locator("input[name='site_settings[copyright]']")
    assert_equal "テスト著作者", copyright_input.input_value
  end

  test "should redirect to login when not authenticated" do
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_url(/.*\/admin\/login/)
    
    # Verify we're on the login page
    assert_match /\/admin\/login/, @page.url
  end
end
