require "application_system_test_case"

class DropdownTurboNavigationTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  test "dropdown works after turbo navigation between admin pages" do
    login_as_admin(@admin)
    
    # Start on articles page
    visit admin_articles_path
    
    # Verify dropdown works on articles page
    find(DROPDOWN_BUTTON).click
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert dropdown_menu[:class].include?('is-open'), "Menu should work on articles page"
    
    # Close dropdown
    find(DROPDOWN_BUTTON).click
    sleep 0.2
    
    # Navigate to site settings page (this uses Turbo navigation)
    find('a[title="サイト設定"]').click
    
    # Verify dropdown still works after Turbo navigation
    find(DROPDOWN_BUTTON).click
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert dropdown_menu[:class].include?('is-open'), "Menu should work after Turbo navigation"
    
    # Test ESC key still works after navigation
    page.send_keys :escape
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert_not dropdown_menu[:class].include?('is-open'), "ESC should work after Turbo navigation"
  end

  test "dropdown initialization doesn't create duplicate event listeners" do
    login_as_admin(@admin)
    
    # Visit page multiple times to trigger multiple initializations
    visit admin_articles_path
    visit admin_site_settings_path
    visit admin_articles_path
    
    # Dropdown should still work normally (no JS errors from duplicate listeners)
    find(DROPDOWN_BUTTON).click
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert dropdown_menu[:class].include?('is-open'), "Menu should work after multiple page loads"
    
    # Outside click should still work (only one event listener should respond)
    find('header').click
    sleep 0.2
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert_not dropdown_menu[:class].include?('is-open'), "Outside click should work correctly"
  end

  test "dropdown css transitions complete before interaction" do
    login_as_admin(@admin)
    
    visit admin_articles_path
    
    # Open dropdown
    find(DROPDOWN_BUTTON).click
    
    # Verify it becomes visible after transition
    sleep 0.3  # Wait for 200ms transition + buffer
    profile_link = find(PROFILE_EDIT_LINK, visible: :all)
    # Check that the dropdown menu has is-open class
    dropdown_menu = find('.js-dropdown-menu', visible: false)
    assert dropdown_menu[:class].include?('is-open'), "Menu should be open"
    
    # Should be able to click immediately after transition
    profile_link.click
    assert_current_path edit_admin_profile_path
  end
end