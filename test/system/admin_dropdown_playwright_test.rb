require "application_playwright_test_case"

class AdminDropdownPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  test "admin dropdown opens and closes on click" do
    login_as_admin(@admin)
    
    # Visit admin page
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    # Find the dropdown elements using CSS selectors
    dropdown_button_selector = DROPDOWN_BUTTON
    dropdown_menu_selector = '.js-dropdown-menu'
    
    # Initially, dropdown should be closed
    assert @page.query_selector(dropdown_button_selector), "Dropdown button should exist"
    
    # Check initial state
    dropdown_button = @page.query_selector(dropdown_button_selector)
    assert_equal "false", dropdown_button.get_attribute("aria-expanded")
    
    dropdown_menu = @page.query_selector(dropdown_menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "Menu should not have 'is-open' class initially"
    
    # Click to open dropdown
    @page.click(dropdown_button_selector)
    
    # Wait for dropdown to open using wait_for_function
    @page.wait_for_function("
      () => document.querySelector('#{dropdown_menu_selector}').classList.contains('is-open')
    ")
    
    # Verify opened state
    dropdown_button = @page.query_selector(dropdown_button_selector)
    assert_equal "true", dropdown_button.get_attribute("aria-expanded")
    
    dropdown_menu = @page.query_selector(dropdown_menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should have 'is-open' class"
    
    # Click to close dropdown
    @page.click('.js-dropdown-button')
    
    # Wait for dropdown to close
    @page.wait_for_function("
      () => !document.querySelector('#{dropdown_menu_selector}').classList.contains('is-open')
    ")
    
    # Verify closed state
    dropdown_button = @page.query_selector('.js-dropdown-button')
    assert_equal "false", dropdown_button.get_attribute("aria-expanded")
    
    dropdown_menu = @page.query_selector(dropdown_menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "Menu should not have 'is-open' class"
  end

  test "admin dropdown closes when clicking outside" do
    login_as_admin(@admin)
    
    # Visit admin page
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    dropdown_button_selector = DROPDOWN_BUTTON
    dropdown_menu_selector = '.js-dropdown-menu'
    
    # Open dropdown
    @page.click(dropdown_button_selector)
    
    # Wait for dropdown to open
    @page.wait_for_function("
      () => document.querySelector('#{dropdown_menu_selector}').classList.contains('is-open')
    ")
    
    dropdown_menu = @page.query_selector(dropdown_menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should have 'is-open' class"
    
    # Click outside the dropdown (on the header)
    @page.click('header')
    
    # Wait for dropdown to close
    @page.wait_for_function("
      () => !document.querySelector('#{dropdown_menu_selector}').classList.contains('is-open')
    ")
    
    # Verify closed state
    dropdown_menu = @page.query_selector(dropdown_menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "Menu should not have 'is-open' class"
    
    dropdown_button = @page.query_selector('.js-dropdown-button')
    assert_equal "false", dropdown_button.get_attribute("aria-expanded")
  end

  test "admin dropdown closes on escape key" do
    login_as_admin(@admin)
    
    # Visit admin page
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    dropdown_button_selector = DROPDOWN_BUTTON
    dropdown_menu_selector = '.js-dropdown-menu'
    
    # Open dropdown
    @page.click(dropdown_button_selector)
    
    # Wait for dropdown to open
    @page.wait_for_function("
      () => document.querySelector('#{dropdown_menu_selector}').classList.contains('is-open')
    ")
    
    dropdown_menu = @page.query_selector(dropdown_menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should have 'is-open' class"
    
    # Press escape key
    @page.keyboard.press("Escape")
    
    # Wait for dropdown to close
    @page.wait_for_function("
      () => !document.querySelector('#{dropdown_menu_selector}').classList.contains('is-open')
    ")
    
    # Verify closed state
    dropdown_menu = @page.query_selector(dropdown_menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "Menu should not have 'is-open' class"
    
    dropdown_button = @page.query_selector('.js-dropdown-button')
    assert_equal "false", dropdown_button.get_attribute("aria-expanded")
  end

  test "admin can navigate to profile through dropdown" do
    login_as_admin(@admin)
    
    # Visit admin page
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    dropdown_button_selector = DROPDOWN_BUTTON
    dropdown_menu_selector = '.js-dropdown-menu'
    
    # Open dropdown
    @page.click(dropdown_button_selector)
    
    # Wait for dropdown to open
    @page.wait_for_function("
      () => document.querySelector('#{dropdown_menu_selector}').classList.contains('is-open')
    ")
    
    dropdown_menu = @page.query_selector(dropdown_menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should have 'is-open' class"
    
    # Click profile edit link - wait for it to be clickable
    profile_link_selector = PROFILE_EDIT_LINK
    @page.wait_for_selector(profile_link_selector)
    @page.click(profile_link_selector)
    
    # Should be on profile edit page
    @page.wait_for_url(/.*\/admin\/profile\/edit/)
    
    # Verify we're on the right page
    page_title = @page.query_selector(PROFILE_EDIT_TITLE)
    assert page_title, "Profile edit title should exist"
    assert_equal "プロフィール編集", page_title.inner_text
  end

end
