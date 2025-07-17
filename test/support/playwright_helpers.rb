# test/support/playwright_helpers.rb
class PlaywrightSetupError < StandardError; end

module PlaywrightHelpers
  # Playwright authentication helper
  def login_as_admin(admin, page: @page, server_port: @server_port)
    page.goto("http://localhost:#{server_port}/admin/login")
    page.fill("#email", admin.email)
    page.fill("#password", TestConfig::TEST_ADMIN_PASSWORD)
    page.click("button[type='submit']")
    page.wait_for_url(/.*\/admin\/articles/)
  end

  # Dropdown operation helpers
  def open_dropdown(page: @page, button_selector: DROPDOWN_BUTTON, menu_selector: '.js-dropdown-menu')
    page.click(button_selector)
    page.wait_for_function("
      () => document.querySelector('#{menu_selector}').classList.contains('is-open')
    ")
  end

  def close_dropdown(page: @page, button_selector: DROPDOWN_BUTTON, menu_selector: '.js-dropdown-menu')
    page.click(button_selector)
    page.wait_for_function("
      () => !document.querySelector('#{menu_selector}').classList.contains('is-open')
    ")
  end

  def assert_dropdown_open(page: @page, menu_selector: '.js-dropdown-menu', button_selector: DROPDOWN_BUTTON)
    dropdown_menu = page.query_selector(menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert class_attr.include?('is-open'), "Menu should have 'is-open' class"
    
    dropdown_button = page.query_selector(button_selector)
    assert_equal "true", dropdown_button.get_attribute("aria-expanded")
  end

  def assert_dropdown_closed(page: @page, menu_selector: '.js-dropdown-menu', button_selector: DROPDOWN_BUTTON)
    dropdown_menu = page.query_selector(menu_selector)
    class_attr = dropdown_menu.get_attribute("class")
    assert_not class_attr.include?('is-open'), "Menu should not have 'is-open' class"
    
    dropdown_button = page.query_selector(button_selector)
    assert_equal "false", dropdown_button.get_attribute("aria-expanded")
  end

  # Navigation helpers
  def visit_admin_articles(page: @page, server_port: @server_port)
    page.goto("http://localhost:#{server_port}/admin/articles")
  end

  def visit_admin_profile_edit(page: @page, server_port: @server_port)
    page.goto("http://localhost:#{server_port}/admin/profile/edit")
  end

  # Form filling helpers
  def fill_password_form(page: @page, password: "newpassword456", confirmation: nil)
    confirmation ||= password
    page.fill(".spec--password-input", password)
    page.fill(".spec--password-confirmation-input", confirmation)
  end

  # Wait and assertion helpers
  def wait_for_page_load(page: @page, state: 'networkidle')
    page.wait_for_load_state(state: state)
  end

  def assert_on_page(page: @page, url_pattern:, title_selector: nil, expected_title: nil)
    page.wait_for_url(url_pattern)
    assert_match url_pattern, page.url
    
    if title_selector && expected_title
      title_element = page.query_selector(title_selector)
      assert title_element, "Title element should exist: #{title_selector}"
      assert_equal expected_title, title_element.inner_text
    end
  end
end