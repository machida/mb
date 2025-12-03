require "application_playwright_test_case"

class AuthorDisplayTogglePlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
    # Create test admins (避重複する email を使用)
    @admin1 = Admin.create!(
      email: "test_author1@example.com",
      user_id: "test_author1",
      password: TEST_ADMIN_PASSWORD,
      password_confirmation: TEST_ADMIN_PASSWORD
    )
    
    @admin2 = Admin.create!(
      email: "test_author2@example.com", 
      user_id: "test_author2",
      password: TEST_ADMIN_PASSWORD,
      password_confirmation: TEST_ADMIN_PASSWORD
    )
    
    # Create articles by different authors
    @article1 = Article.create!(
      title: "Article by Author 1",
      body: "Content by author 1",
      author: @admin1.user_id,
      draft: false
    )
    
    @article2 = Article.create!(
      title: "Article by Author 2",
      body: "Content by author 2",
      author: @admin2.user_id,
      draft: false
    )
    
    # Set initial state: author display enabled
    SiteSetting.set("author_display_enabled", "true")
  end

  test "admin can toggle author display setting" do
    login_as_admin

    # Navigate to site settings
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_selector(".spec--site-settings-title")

    # Check that author display is enabled by default
    enabled_radio = @page.locator("input.spec--author-display-enabled-true")
    assert enabled_radio.checked?

    # Toggle to disabled
    disabled_radio = @page.locator("input.spec--author-display-enabled-false")
    disabled_radio.click

    # Save settings
    @page.click("input.spec--save-button")
    @page.wait_for_selector(".spec--toast-notification", timeout: 10000)

    # Verify setting was saved
    assert_equal "false", SiteSetting.get("author_display_enabled")
  end

  test "author info is not displayed when setting is disabled" do
    # Disable author display
    SiteSetting.set("author_display_enabled", "false")
    
    # Visit homepage
    @page.goto("http://localhost:#{@server_port}/")
    
    # Author info should not be displayed
    author_elements = @page.locator(".spec--article-author")
    assert_equal 0, author_elements.count
  end

  test "author info is displayed when setting is enabled" do
    # Enable author display
    SiteSetting.set("author_display_enabled", "true")
    
    # Visit homepage
    @page.goto("http://localhost:#{@server_port}/")
    
    # Author info should be displayed
    author_elements = @page.locator(".spec--article-author")
    assert author_elements.count > 0
  end

  test "author info on article detail page respects setting" do
    # Enable author display first
    SiteSetting.set("author_display_enabled", "true")
    
    # Ensure article exists and is published
    @article1.reload
    assert @article1.persisted?, "Article should be persisted"
    assert_not @article1.draft, "Article should be published"
    
    # Visit article detail page using the correct path format
    @page.goto("http://localhost:#{@server_port}/article/#{@article1.id}")
    
    # Wait for page to load
    @page.wait_for_load_state(state: 'networkidle')
    
    # Debug: check if show_author_info? is working
    Rails.logger.debug "Published articles count: #{Article.published.count}"
    Rails.logger.debug "Distinct authors count: #{Article.published.select(:author).distinct.count}"
    Rails.logger.debug "Author display enabled: #{SiteSetting.author_display_enabled}"
    
    # Author info should be displayed
    author_element = @page.locator(".spec--article-author")
    assert author_element.count > 0, "Author element should be visible when author display is enabled. Page content: #{@page.text_content('body')}"
    
    # Disable author display
    SiteSetting.set("author_display_enabled", "false")
    
    # Refresh page
    @page.reload
    @page.wait_for_load_state(state: 'networkidle')
    
    # Author info should not be displayed
    author_element = @page.locator(".spec--article-author")
    assert_equal 0, author_element.count, "Author element should not be visible when author display is disabled"
  end

  test "site settings form shows correct default value" do
    login_as_admin

    # Test with enabled setting
    SiteSetting.set("author_display_enabled", "true")
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_selector(".spec--site-settings-title")

    enabled_radio = @page.locator("input.spec--author-display-enabled-true")
    assert enabled_radio.checked?

    # Test with disabled setting
    SiteSetting.set("author_display_enabled", "false")
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_selector(".spec--site-settings-title")

    disabled_radio = @page.locator("input.spec--author-display-enabled-false")
    assert disabled_radio.checked?
  end
end