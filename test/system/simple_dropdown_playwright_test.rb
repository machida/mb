require "application_playwright_test_case"

class SimpleDropdownPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  test "dropdown elements exist on admin page" do
    login_as_admin(@admin)
    
    # Visit admin page
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    # Check that dropdown elements exist
    dropdown_button = @page.query_selector('.js-dropdown-button')
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    
    assert dropdown_button, "Dropdown button should exist"
    assert dropdown_menu, "Dropdown menu should exist"
    
    # Check initial state - menu should not have 'is-open' class
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "Menu should not have 'is-open' class initially"
    
    # Check button attributes
    assert_equal "false", dropdown_button.get_attribute("aria-expanded")
  end

  test "dropdown javascript functionality works" do
    login_as_admin(@admin)
    
    # Visit admin page
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    # Find elements
    dropdown_button = @page.query_selector('.js-dropdown-button')
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    
    # Initial state should be closed
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "Menu should not have 'is-open' class initially"
    assert_equal "false", dropdown_button.get_attribute("aria-expanded")
    
    # Click to open
    @page.click('.js-dropdown-button')
    
    # Wait for JavaScript to execute using wait_for_function
    @page.wait_for_function("
      () => document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    # Check updated state
    dropdown_button = @page.query_selector('.js-dropdown-button')
    dropdown_menu = @page.query_selector('.js-dropdown-menu')
    
    # Should now be open
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should have 'is-open' class after click"
    assert_equal "true", dropdown_button.get_attribute("aria-expanded"), "Button aria-expanded should be true"
  end
end
