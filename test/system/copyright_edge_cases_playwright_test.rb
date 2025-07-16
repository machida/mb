require "application_playwright_test_case"

class CopyrightEdgeCasesPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  private
  
  def submit_settings_and_wait
    @page.click("button:has-text('設定を保存')")
    @page.wait_for_url(/.*\/admin\/site_settings/)
    
    # Wait for any async operations to complete and force cache clearing
    @page.wait_for_load_state('networkidle')
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
  end

  test "changing copyright when starting with default value from seeds" do
    # Reset to exact seeds value
    SiteSetting.set('copyright', 'マチダのブログ')
    
    login_as_admin(@admin)
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    
    # Try to change to a user-provided value (simulating real usage)
    @page.fill("input[name='site_settings[copyright]']", "ユーザー提供の著作権者名")
    submit_settings_and_wait
    
    assert_equal "ユーザー提供の著作権者名", get_current_copyright
    
    copyright_field = @page.query_selector(COPYRIGHT_INPUT)
    assert_equal "ユーザー提供の著作権者名", copyright_field.input_value
  end

  test "changing copyright when it contains current year" do
    # Set a copyright that might confuse the system
    SiteSetting.set('copyright', "© #{Date.current.year} 古い会社名. All rights reserved.")
    
    login_as_admin(@admin)
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    
    # The form should show just the name part, not the full copyright text
    copyright_field = @page.query_selector(COPYRIGHT_INPUT)
    field_value = copyright_field.input_value
    Rails.logger.info "Field shows with year format: #{field_value.inspect}"
    
    # Change to new value
    @page.fill("input[name='site_settings[copyright]']", "新しい会社名")
    submit_settings_and_wait
    
    assert_equal "新しい会社名", get_current_copyright
    
    copyright_field = @page.query_selector(COPYRIGHT_INPUT)
    assert_equal "新しい会社名", copyright_field.input_value
  end

  test "multiple back-to-back copyright changes" do
    SiteSetting.set('copyright', '最初の値')
    
    login_as_admin(@admin)
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    
    # First change
    @page.fill("input[name='site_settings[copyright]']", "2番目の値")
    submit_settings_and_wait
    assert_equal "2番目の値", get_current_copyright
    
    # Second change immediately after
    @page.fill("input[name='site_settings[copyright]']", "3番目の値")
    submit_settings_and_wait
    assert_equal "3番目の値", get_current_copyright
    
    # Third change
    @page.fill("input[name='site_settings[copyright]']", "最終的な値")
    submit_settings_and_wait
    assert_equal "最終的な値", get_current_copyright
    
    copyright_field = @page.query_selector(COPYRIGHT_INPUT)
    assert_equal "最終的な値", copyright_field.input_value
  end

  test "copyright change with page navigation in between" do
    SiteSetting.set('copyright', '初期値')
    
    login_as_admin(@admin)
    
    # Go to settings
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    @page.fill("input[name='site_settings[copyright]']", "中間値")
    submit_settings_and_wait
    
    # Navigate away and back
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    
    # Verify value persisted
    copyright_field = @page.query_selector(COPYRIGHT_INPUT)
    assert_equal "中間値", copyright_field.input_value
    
    # Change again
    @page.fill("input[name='site_settings[copyright]']", "最終値")
    submit_settings_and_wait
    
    assert_equal "最終値", get_current_copyright
    
    copyright_field = @page.query_selector(COPYRIGHT_INPUT)
    assert_equal "最終値", copyright_field.input_value
  end

  test "copyright change with special characters and unicode" do
    SiteSetting.set('copyright', 'Plain Text')
    
    login_as_admin(@admin)
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    
    # Test with Japanese characters
    japanese_text = "株式会社テスト"
    @page.fill("input[name='site_settings[copyright]']", japanese_text)
    submit_settings_and_wait
    assert_equal japanese_text, get_current_copyright
    
    # Test with symbols and numbers
    mixed_text = "Company™ 2025"
    @page.fill("input[name='site_settings[copyright]']", mixed_text)
    submit_settings_and_wait
    assert_equal mixed_text, get_current_copyright
    
    # Test with emojis
    emoji_text = "会社名 🏢"
    @page.fill("input[name='site_settings[copyright]']", emoji_text)
    submit_settings_and_wait
    assert_equal emoji_text, get_current_copyright
  end

  test "verify footer display updates immediately after copyright change" do
    SiteSetting.set('copyright', '古いフッター名')
    
    login_as_admin(@admin)
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    
    # Change copyright
    new_name = "新しいフッター名"
    @page.fill("input[name='site_settings[copyright]']", new_name)
    submit_settings_and_wait
    
    # Go to public page and check footer
    @page.goto("http://localhost:#{@server_port}/")
    expected_footer = "© #{Date.current.year} #{new_name}. All rights reserved."
    
    footer_element = @page.query_selector("footer small")
    assert footer_element, "Footer small element should exist"
    assert_equal expected_footer, footer_element.inner_text
  end
end