require "application_playwright_test_case"

class AdminDropdownPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    @admin = create_admin
  end

  test "admin dropdown opens and closes on click" do
    login_as_admin(@admin, page: @page, server_port: @server_port)
    visit_admin_articles
    
    # Initially, dropdown should be closed
    assert_element_exists(selector: DROPDOWN_BUTTON, message: "Dropdown button should exist")
    assert_dropdown_closed
    
    # Click to open dropdown
    open_dropdown
    assert_dropdown_open
    
    # Click to close dropdown
    close_dropdown
    assert_dropdown_closed
  end

  test "admin dropdown closes when clicking outside" do
    login_as_admin(@admin, page: @page, server_port: @server_port)
    visit_admin_articles
    
    # Open dropdown
    open_dropdown
    assert_dropdown_open
    
    # Click outside the dropdown (on the header)
    @page.click('header')
    
    # Wait for dropdown to close
    @page.wait_for_function("
      () => !document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    assert_dropdown_closed
  end

  test "admin dropdown closes on escape key" do
    login_as_admin(@admin, page: @page, server_port: @server_port)
    visit_admin_articles
    
    # Open dropdown
    open_dropdown
    assert_dropdown_open
    
    # Press escape key
    @page.keyboard.press("Escape")
    
    # Wait for dropdown to close
    @page.wait_for_function("
      () => !document.querySelector('.js-dropdown-menu').classList.contains('is-open')
    ")
    
    assert_dropdown_closed
  end

  test "admin can navigate to profile through dropdown" do
    login_as_admin(@admin, page: @page, server_port: @server_port)
    visit_admin_articles
    
    # Open dropdown
    open_dropdown
    assert_dropdown_open
    
    # Click profile edit link - wait for it to be clickable
    @page.wait_for_selector(PROFILE_EDIT_LINK)
    @page.click(PROFILE_EDIT_LINK)
    
    # Should be on profile edit page
    assert_on_page(
      url_pattern: /.*\/admin\/profile\/edit/,
      title_selector: PROFILE_EDIT_TITLE,
      expected_title: "プロフィール編集"
    )
  end

end
