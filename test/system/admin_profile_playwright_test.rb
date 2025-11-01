require "application_playwright_test_case"

class AdminProfilePlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  test "admin can access profile edit page" do
    login_as_admin(@admin)
    
    # Navigate directly to profile edit page
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    @page.wait_for_url(/.*\/admin\/profile\/edit/)
    
    # Check page elements
    title_element = @page.query_selector(".spec--profile-edit-title")
    assert title_element, "Profile edit title should exist"
    assert_equal "プロフィール編集", title_element.inner_text
    
    assert @page.query_selector(".spec--email-input"), "Email input should exist"
    assert @page.query_selector(".spec--user-id-input"), "User ID input should exist"
    
    password_link = @page.query_selector(".spec--password-change-link")
    assert password_link, "Password change link should exist"
    assert_equal "パスワードを変更", password_link.inner_text
  end

  test "admin can update email and user_id" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    
    # Fill in form fields
    @page.fill(".spec--email-input", "new@example.com")
    @page.fill(".spec--user-id-input", "newuser123")
    @page.click(".spec--update-button")
    
    # Wait for toast notification to appear
    toast_selector = ".spec--toast-notification"
    @page.wait_for_selector(toast_selector, timeout: 10000)
    
    toast_element = @page.query_selector(toast_selector)
    assert toast_element, "Toast notification should appear"
    assert_equal "プロフィールを更新しました。", toast_element.inner_text
    
    # Wait for any async operations to complete
    @page.wait_for_load_state(state: 'networkidle')
    
    # Check if values are updated
    @admin.reload
    assert_equal "new@example.com", @admin.email
    assert_equal "newuser123", @admin.user_id
  end

  test "admin can navigate to password change page" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    
    @page.click("a:has-text('パスワードを変更')")
    
    @page.wait_for_url(/.*\/admin\/password\/edit/)
    
    title_element = @page.query_selector(".spec--password-edit-title")
    assert title_element, "Password edit title should exist"
    assert_equal "パスワード変更", title_element.inner_text
  end

  test "admin sees validation errors for invalid email" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    
    # Try to set an invalid email format
    @page.fill(".spec--email-input", "invalid-email")
    @page.click(".spec--update-button")
    
    # Check if we stayed on the same page due to validation errors
    @page.wait_for_load_state(state: 'networkidle')
    assert_match /\/admin\/profile\/edit/, @page.url, "Should stay on profile edit page"
    
    # Check for HTML5 validation - the field should be invalid
    email_input = @page.query_selector(".spec--email-input")
    assert email_input, "Email input should exist"
    
    # Check if the input has invalid state (HTML5 validation)
    validity_state = @page.evaluate("() => document.querySelector('.spec--email-input').validity.valid")
    assert_equal false, validity_state, "Email input should be invalid"
  end

  test "admin can cancel profile edit" do
    login_as_admin(@admin)

    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")
    @page.click(".spec--cancel-button")

    @page.wait_for_url(/.*\/admin\/articles/)
    assert_match /\/admin\/articles/, @page.url
  end

  test "admin can see theme color section" do
    login_as_admin(@admin)

    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")

    # Check theme section exists
    theme_title = @page.query_selector(".spec--theme-section-title")
    assert theme_title, "Theme section title should exist"
    assert_equal "テーマカラー", theme_title.inner_text

    # Check theme color options exist (22 colors)
    theme_options = @page.query_selector_all(".spec--theme-color-option")
    assert_equal 22, theme_options.length, "Should have 22 theme color options"

    # Check default theme (sky) is selected
    sky_option = @page.query_selector(".spec--theme-color-option[data-color='sky']")
    assert sky_option, "Sky theme option should exist"

    sky_radio = sky_option.query_selector(".spec--theme-color-input")
    assert sky_radio.checked?, "Sky theme should be selected by default"
  end

  test "admin can change theme color" do
    login_as_admin(@admin)

    @page.goto("http://localhost:#{@server_port}/admin/profile/edit")

    # Select a different theme color (indigo)
    indigo_option = @page.query_selector(".spec--theme-color-option[data-color='indigo']")
    assert indigo_option, "Indigo theme option should exist"

    indigo_option.click

    # Submit the form
    @page.click(".spec--update-button")

    # Wait for toast notification
    toast_selector = ".spec--toast-notification"
    @page.wait_for_selector(toast_selector, timeout: 10000)

    # Check if theme color is updated in database
    @admin.reload
    assert_equal "indigo", @admin.theme_color

    # Check if body has the new theme class
    @page.wait_for_load_state(state: 'networkidle')
    body_classes = @page.evaluate("() => document.body.className")
    assert_includes body_classes, "is--indigo", "Body should have indigo theme class"
  end
end
