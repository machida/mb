require "application_playwright_test_case"

class DropdownTurboNavigationPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super

    # Clear test data
    Article.destroy_all
    Admin.destroy_all

    @admin = create_admin
  end

  test "dropdown works after turbo navigation between admin pages" do
    login_as_admin(@admin)

    # Start on articles page
    @page.goto("http://localhost:#{@server_port}/admin/articles")

    # Wait for page to be fully loaded
    @page.wait_for_load_state(state: 'networkidle')

    # Verify dropdown works on articles page
    @page.click(DROPDOWN_BUTTON)
    @page.wait_for_function("
      () => document.querySelector('.js--dropdown-menu').classList.contains('is--open')
    ")

    dropdown_menu = @page.query_selector('.js--dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is--open'), "Menu should work on articles page"

    # Close dropdown
    @page.click(DROPDOWN_BUTTON)
    @page.wait_for_function("
      () => !document.querySelector('.js--dropdown-menu').classList.contains('is--open')
    ")

    # Navigate to site settings page (this uses Turbo navigation)
    # Try multiple selectors to find the site settings link
    site_settings_selectors = [
      'a[aria-label="サイト設定"]',
      'a[href*="site-settings"]',
      'a[href*="site_settings"]',
      'text=サイト設定'
    ]

    site_settings_link = nil
    site_settings_selectors.each do |selector|
      begin
        link = @page.locator(selector)
        link.wait_for(state: 'visible', timeout: 2000)
        site_settings_link = link
        break
      rescue Playwright::TimeoutError
        # Try next selector
        next
      end
    end

    raise "Site settings link not found with any selector" unless site_settings_link

    site_settings_link.click()

    # Wait for Turbo navigation to complete with longer timeout
    @page.wait_for_url(/.*\/admin\/site[-_]settings/, timeout: 15000)
    @page.wait_for_load_state(state: 'networkidle')

    # Wait for any JavaScript re-initialization to complete with longer timeout
    @page.wait_for_function("
      () => document.querySelector('.js--dropdown-button') &&
            document.querySelector('.js--dropdown-button').hasAttribute('data-dropdown-initialized')
    ", timeout: 10000)

    # Verify dropdown still works after Turbo navigation
    @page.click(DROPDOWN_BUTTON)
    @page.wait_for_function("
      () => document.querySelector('.js--dropdown-menu').classList.contains('is--open')
    ")

    dropdown_menu = @page.query_selector('.js--dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is--open'), "Menu should work after Turbo navigation"

    # Test ESC key still works after navigation
    @page.keyboard.press("Escape")
    @page.wait_for_function("
      () => !document.querySelector('.js--dropdown-menu').classList.contains('is--open')
    ")

    dropdown_menu = @page.query_selector('.js--dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is--open'), "ESC should work after Turbo navigation"
  end

  test "dropdown initialization doesn't create duplicate event listeners" do
    login_as_admin(@admin)

    # Visit page multiple times to trigger multiple initializations
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.goto("http://localhost:#{@server_port}/admin/articles")

    # Dropdown should still work normally (no JS errors from duplicate listeners)
    @page.click(DROPDOWN_BUTTON)
    @page.wait_for_function("
      () => document.querySelector('.js--dropdown-menu').classList.contains('is--open')
    ")

    dropdown_menu = @page.query_selector('.js--dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is--open'), "Menu should work after multiple page loads"

    # Outside click should still work (only one event listener should respond)
    @page.click('header')
    @page.wait_for_function("
      () => !document.querySelector('.js--dropdown-menu').classList.contains('is--open')
    ")

    dropdown_menu = @page.query_selector('.js--dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is--open'), "Outside click should work correctly"
  end

  test "dropdown css transitions complete before interaction" do
    login_as_admin(@admin)

    @page.goto("http://localhost:#{@server_port}/admin/articles")

    # Open dropdown
    @page.click(DROPDOWN_BUTTON)

    # Wait for dropdown to open and transitions to complete
    @page.wait_for_function("
      () => document.querySelector('.js--dropdown-menu').classList.contains('is--open')
    ")

    # Check that the dropdown menu has is--open class
    dropdown_menu = @page.query_selector('.js--dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is--open'), "Menu should be open"

    # Should be able to click profile link immediately after transition
    # Playwright automatically waits for elements to be actionable
    profile_link_selector = PROFILE_EDIT_LINK
    @page.wait_for_selector(profile_link_selector)
    @page.click(profile_link_selector)

    # Verify navigation
    @page.wait_for_url(/.*\/admin\/profile\/edit/)
  end
end
