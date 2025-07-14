require "application_system_test_case"

class AdminDropdownTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  test "admin dropdown opens and closes on click" do
    login_as_admin(@admin)
    
    # Visit admin page
    visit admin_articles_path
    
    # Find the dropdown button
    dropdown_button = find(DROPDOWN_BUTTON)
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    
    # Initially, dropdown should be closed
    assert_not dropdown_menu.visible?
    assert_equal "false", dropdown_button["aria-expanded"]
    
    # Click to open dropdown
    dropdown_button.click
    
    # Wait for JavaScript to execute and check class is added
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert dropdown_menu[:class].include?('is-open'), "Menu should have 'is-open' class"
    assert_equal "true", find('.js-dropdown-button')["aria-expanded"]
    
    # Click to close dropdown
    find('.js-dropdown-button').click
    
    # Wait for JavaScript to execute and check class is removed
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert_not dropdown_menu[:class].include?('is-open'), "Menu should not have 'is-open' class"
    assert_equal "false", find('.js-dropdown-button')["aria-expanded"]
  end

  test "admin dropdown closes when clicking outside" do
    login_as_admin(@admin)
    
    # Visit admin page
    visit admin_articles_path
    
    # Open dropdown
    find(DROPDOWN_BUTTON).click
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert dropdown_menu[:class].include?('is-open'), "Menu should have 'is-open' class"
    
    # Click outside the dropdown (on the header)
    find('header').click
    
    # Wait for JavaScript to execute and check state
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert_not dropdown_menu[:class].include?('is-open'), "Menu should not have 'is-open' class"
    assert_equal "false", find('.js-dropdown-button')["aria-expanded"]
  end

  test "admin dropdown closes on escape key" do
    login_as_admin(@admin)
    
    # Visit admin page
    visit admin_articles_path
    
    # Open dropdown
    find(DROPDOWN_BUTTON).click
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert dropdown_menu[:class].include?('is-open'), "Menu should have 'is-open' class"
    
    # Press escape key
    page.send_keys :escape
    
    # Wait for JavaScript to execute and check state
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert_not dropdown_menu[:class].include?('is-open'), "Menu should not have 'is-open' class"
    assert_equal "false", find('.js-dropdown-button')["aria-expanded"]
  end

  test "admin can navigate to profile through dropdown" do
    login_as_admin(@admin)
    
    # Visit admin page
    visit admin_articles_path
    
    # Open dropdown
    find(DROPDOWN_BUTTON).click
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert dropdown_menu[:class].include?('is-open'), "Menu should have 'is-open' class"
    
    # Wait for CSS transition to complete (200ms transition + buffer)
    sleep 0.3
    
    # Click profile edit link - find with visible: :all since CSS controls visibility
    profile_link = find(PROFILE_EDIT_LINK, visible: :all)
    # Use JavaScript click to ensure interaction works regardless of CSS visibility state
    profile_link.execute_script("this.click()")
    
    # Should be on profile edit page
    assert_current_path edit_admin_profile_path
    assert_selector PROFILE_EDIT_TITLE, text: "プロフィール編集"
  end
end