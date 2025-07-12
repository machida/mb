require "application_system_test_case"

class SimpleDropdownTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  test "dropdown elements exist on admin page" do
    login_as_admin(@admin)
    
    # Visit admin page
    visit admin_articles_path
    
    # Check that dropdown elements exist (including hidden ones)
    assert_selector '.js-dropdown-button', count: 1
    assert_selector '.js-dropdown-menu', visible: :all, count: 1
    
    # Find elements specifically allowing hidden ones
    dropdown_button = find('.js-dropdown-button')
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    
    # Check initial state - menu should not have 'is-open' class
    assert_not dropdown_menu[:class].include?('is-open')
    
    # Check button attributes
    assert_equal "false", dropdown_button["aria-expanded"]
  end

  test "dropdown javascript functionality works" do
    login_as_admin(@admin)
    
    # Visit admin page
    visit admin_articles_path
    
    # Find elements
    dropdown_button = find('.js-dropdown-button')
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    
    # Initial state should be closed
    assert_not dropdown_menu[:class].include?('is-open')
    assert_equal "false", dropdown_button["aria-expanded"]
    
    # Click to open
    dropdown_button.click
    
    # Wait a moment for JavaScript to execute
    sleep 0.1
    
    # Reload elements to check updated state
    dropdown_button = find('.js-dropdown-button')
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    
    # Should now be open
    assert dropdown_menu[:class].include?('is-open'), "Menu should have 'is-open' class after click"
    assert_equal "true", dropdown_button["aria-expanded"], "Button aria-expanded should be true"
  end
end