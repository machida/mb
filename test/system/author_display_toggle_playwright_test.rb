require "application_playwright_test_case"

class AuthorDisplayTogglePlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
    # Create test admins
    @admin1 = Admin.create!(
      email: "admin1@example.com",
      user_id: "author1",
      password: "password123",
      password_confirmation: "password123"
    )
    
    @admin2 = Admin.create!(
      email: "admin2@example.com", 
      user_id: "author2",
      password: "password123",
      password_confirmation: "password123"
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
    @page.wait_for_selector("h1:has-text('サイト設定')")

    # Check that author display is enabled by default
    enabled_radio = @page.locator("input.spec--author-display-enabled-true")
    assert enabled_radio.checked?

    # Toggle to disabled
    disabled_radio = @page.locator("input.spec--author-display-enabled-false")
    disabled_radio.click

    # Save settings
    @page.click("input.spec--save-button")
    @page.wait_for_selector("div.notice")

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
    
    # Visit article detail page
    @page.goto("http://localhost:#{@server_port}/articles/#{@article1.id}")
    
    # Author info should be displayed
    author_element = @page.locator(".spec--article-author")
    assert author_element.count > 0
    
    # Disable author display
    SiteSetting.set("author_display_enabled", "false")
    
    # Refresh page
    @page.reload
    
    # Author info should not be displayed
    author_element = @page.locator(".spec--article-author")
    assert_equal 0, author_element.count
  end

  test "site settings form shows correct default value" do
    login_as_admin

    # Test with enabled setting
    SiteSetting.set("author_display_enabled", "true")
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_selector("h1:has-text('サイト設定')")

    enabled_radio = @page.locator("input.spec--author-display-enabled-true")
    assert enabled_radio.checked?

    # Test with disabled setting
    SiteSetting.set("author_display_enabled", "false")
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_selector("h1:has-text('サイト設定')")

    disabled_radio = @page.locator("input.spec--author-display-enabled-false")
    assert disabled_radio.checked?
  end
end