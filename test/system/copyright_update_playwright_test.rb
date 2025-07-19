require "application_playwright_test_case"

class CopyrightUpdatePlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
    
    # Reset copyright to known state
    SiteSetting.set('copyright', 'テスト著作権者')
  end

  private
  
  def submit_settings_and_wait
    # Wait for save button to be available
    @page.wait_for_selector("input[type='submit'][value='設定を保存']", timeout: 5000)
    @page.click("input[type='submit'][value='設定を保存']")
    @page.wait_for_url(/.*\/admin\/site-settings/)
    
    # Wait for any async operations to complete and force cache clearing
    @page.wait_for_load_state(state: 'networkidle')
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
  end

  test "admin can update copyright holder name" do
    login_as_admin(@admin)
    
    # Visit site settings page
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for the admin page title to be visible first to ensure we're on the right page
    @page.wait_for_selector("h1:has-text('サイト設定')", timeout: 10000)
    
    # Wait for copyright input to be available (try both selectors)
    copyright_selector = nil
    begin
      @page.wait_for_selector(COPYRIGHT_INPUT, timeout: 5000)
      copyright_selector = COPYRIGHT_INPUT
    rescue Playwright::TimeoutError
      @page.wait_for_selector("input[name='site_settings[copyright]']", timeout: 5000)
      copyright_selector = "input[name='site_settings[copyright]']"
    end
    
    # Verify current copyright value is displayed
    copyright_input = @page.locator(copyright_selector)
    assert_equal "テスト著作権者", copyright_input.input_value
    
    # Update copyright holder name
    @page.fill("input[name='site_settings[copyright]']", "新しい著作権者名")
    
    # Save changes
    submit_settings_and_wait
    # Note: Toast notification testing is handled in other system tests
    
    # Wait for the admin page title to be visible to ensure page is fully loaded
    @page.wait_for_selector("h1:has-text('サイト設定')", timeout: 10000)
    
    # Verify the field shows updated value
    copyright_input = @page.locator(copyright_selector)
    assert_equal "新しい著作権者名", copyright_input.input_value
    
    # Wait for database sync and verify the setting was actually saved
    sleep 0.1
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
    assert_equal "新しい著作権者名", get_current_copyright
  end

  test "admin can clear copyright holder name" do
    login_as_admin(@admin)
    
    # Visit site settings page
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for the admin page title to be visible first to ensure we're on the right page
    @page.wait_for_selector("h1:has-text('サイト設定')", timeout: 10000)
    
    # Wait for copyright input to be available (try both selectors)
    copyright_selector = nil
    begin
      @page.wait_for_selector(COPYRIGHT_INPUT, timeout: 5000)
      copyright_selector = COPYRIGHT_INPUT
    rescue Playwright::TimeoutError
      @page.wait_for_selector("input[name='site_settings[copyright]']", timeout: 5000)
      copyright_selector = "input[name='site_settings[copyright]']"
    end
    
    # Clear copyright field (empty string)
    @page.fill("input[name='site_settings[copyright]']", "")
    
    # Save changes
    submit_settings_and_wait
    
    # Wait for the admin page title to be visible to ensure page is fully loaded
    @page.wait_for_selector("h1:has-text('サイト設定')", timeout: 10000)
    
    # Verify the field is empty
    copyright_input = @page.locator(copyright_selector)
    assert_equal "", copyright_input.input_value
    
    # Wait for database sync and verify the setting was actually cleared
    sleep 0.1
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
    assert_equal "", get_current_copyright
  end

  test "admin can update copyright with whitespace that gets trimmed" do
    login_as_admin(@admin)
    
    # Visit site settings page
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for the admin page title to be visible first to ensure we're on the right page
    @page.wait_for_selector("h1:has-text('サイト設定')", timeout: 10000)
    
    # Wait for copyright input to be available (try both selectors)
    copyright_selector = nil
    begin
      @page.wait_for_selector(COPYRIGHT_INPUT, timeout: 5000)
      copyright_selector = COPYRIGHT_INPUT
    rescue Playwright::TimeoutError
      @page.wait_for_selector("input[name='site_settings[copyright]']", timeout: 5000)
      copyright_selector = "input[name='site_settings[copyright]']"
    end
    
    # Update copyright with leading/trailing spaces
    @page.fill("input[name='site_settings[copyright]']", "  スペース付き著作権者  ")
    
    # Save changes
    submit_settings_and_wait
    
    # Wait for the admin page title to be visible to ensure page is fully loaded
    @page.wait_for_selector("h1:has-text('サイト設定')", timeout: 10000)
    
    # Wait for database sync and verify whitespace was trimmed
    sleep 0.1
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
    assert_equal "スペース付き著作権者", get_current_copyright
    
    # Note: Form field may still show spaces until page refresh
    # The important part is that database value is trimmed
  end

  test "copyright displays correctly in public layout after update" do
    login_as_admin(@admin)
    
    # Update copyright through admin interface
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for the admin page title to be visible first to ensure we're on the right page
    @page.wait_for_selector("h1:has-text('サイト設定')", timeout: 10000)
    
    # Wait for copyright input to be available (try both selectors)
    copyright_selector = nil
    begin
      @page.wait_for_selector(COPYRIGHT_INPUT, timeout: 5000)
      copyright_selector = COPYRIGHT_INPUT
    rescue Playwright::TimeoutError
      @page.wait_for_selector("input[name='site_settings[copyright]']", timeout: 5000)
      copyright_selector = "input[name='site_settings[copyright]']"
    end
    
    @page.fill("input[name='site_settings[copyright]']", "新しいブログ名")
    submit_settings_and_wait
    
    # Visit public page to verify copyright display
    @page.goto("http://localhost:#{@server_port}/")
    
    # Check that copyright is displayed with proper format in footer
    expected_text = "© #{Date.current.year} 新しいブログ名. All rights reserved."
    footer_element = @page.query_selector("footer small")
    assert footer_element, "Footer small element should exist"
    assert_equal expected_text, footer_element.inner_text
  end

  test "copyright does not display in footer when empty" do
    login_as_admin(@admin)
    
    # Clear copyright through admin interface
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for the admin page title to be visible first to ensure we're on the right page
    @page.wait_for_selector("h1:has-text('サイト設定')", timeout: 10000)
    
    # Wait for copyright input to be available (try both selectors)
    copyright_selector = nil
    begin
      @page.wait_for_selector(COPYRIGHT_INPUT, timeout: 5000)
      copyright_selector = COPYRIGHT_INPUT
    rescue Playwright::TimeoutError
      @page.wait_for_selector("input[name='site_settings[copyright]']", timeout: 5000)
      copyright_selector = "input[name='site_settings[copyright]']"
    end
    
    @page.fill("input[name='site_settings[copyright]']", "")
    submit_settings_and_wait
    
    # Visit public page to verify no copyright display
    @page.goto("http://localhost:#{@server_port}/")
    
    # Check that no copyright text is displayed in footer
    footer_element = @page.query_selector("footer small")
    if footer_element
      footer_text = footer_element.inner_text
      assert_no_match /© #{Date.current.year}/, footer_text
    else
      # Footer element should exist but may be empty
      assert @page.query_selector("footer"), "Footer should exist"
    end
  end

  test "copyright format follows expected pattern with SiteSetting.copyright_text method" do
    # Test the model method directly
    SiteSetting.set('copyright', 'テストユーザー')
    expected = "© #{Date.current.year} テストユーザー. All rights reserved."
    assert_equal expected, SiteSetting.copyright_text
    
    # Test with empty copyright (now allowed)
    SiteSetting.set('copyright', '')
    expected_empty = "© #{Date.current.year} . All rights reserved."
    assert_equal expected_empty, SiteSetting.copyright_text
  end
end
