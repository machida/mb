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
    
    # Verify dropdown works on articles page
    @page.click(DROPDOWN_BUTTON)
    @page.wait_for_function("
      () => document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should work on articles page"
    
    # Close dropdown
    @page.click(DROPDOWN_BUTTON)
    @page.wait_for_function("
      () => !document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    # Navigate to site settings page (this uses Turbo navigation)
    @page.click('a[title="サイト設定"]')
    
    # Wait for Turbo navigation to complete
    @page.wait_for_url(/.*\/admin\/site_settings/)
    
    # Wait for any JavaScript re-initialization to complete
    @page.wait_for_function("
      () => document.querySelector('.js-dropdown-button').hasAttribute('data-dropdown-initialized')
    ")
    
    # Verify dropdown still works after Turbo navigation
    @page.click(DROPDOWN_BUTTON)
    @page.wait_for_function("
      () => document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should work after Turbo navigation"
    
    # Test ESC key still works after navigation
    @page.keyboard.press("Escape")
    @page.wait_for_function("
      () => !document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "ESC should work after Turbo navigation"
  end

  test "dropdown initialization doesn't create duplicate event listeners" do
    login_as_admin(@admin)
    
    # Visit page multiple times to trigger multiple initializations
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    # Dropdown should still work normally (no JS errors from duplicate listeners)
    @page.click(DROPDOWN_BUTTON)
    @page.wait_for_function("
      () => document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should work after multiple page loads"
    
    # Outside click should still work (only one event listener should respond)
    @page.click('header')
    @page.wait_for_function("
      () => !document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "Outside click should work correctly"
  end

  test "dropdown css transitions complete before interaction" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    # Open dropdown
    @page.click(DROPDOWN_BUTTON)
    
    # Wait for dropdown to open and transitions to complete
    @page.wait_for_function("
      () => document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    # Check that the dropdown menu has is-open class
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should be open"
    
    # Should be able to click profile link immediately after transition
    # Playwright automatically waits for elements to be actionable
    profile_link_selector = PROFILE_EDIT_LINK
    @page.wait_for_selector(profile_link_selector)
    @page.click(profile_link_selector)
    
    # Verify navigation
    @page.wait_for_url(/.*\/admin\/profile\/edit/)
  end
end