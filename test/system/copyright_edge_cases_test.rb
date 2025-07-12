require "application_system_test_case"

class CopyrightEdgeCasesTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
  end

  test "changing copyright when starting with default value from seeds" do
    # Reset to exact seeds value
    SiteSetting.set('copyright', 'マチダのブログ')
    
    login_as_admin(@admin)
    visit admin_site_settings_path
    
    # Try to change to a user-provided value (simulating real usage)
    fill_in "site_settings[copyright]", with: "ユーザー提供の著作権者名"
    click_button "設定を保存"
    
    assert_current_path admin_site_settings_path
    assert_equal "ユーザー提供の著作権者名", SiteSetting.copyright
    assert_equal "ユーザー提供の著作権者名", find(COPYRIGHT_INPUT).value
  end

  test "changing copyright when it contains current year" do
    # Set a copyright that might confuse the system
    SiteSetting.set('copyright', "© #{Date.current.year} 古い会社名. All rights reserved.")
    
    login_as_admin(@admin)
    visit admin_site_settings_path
    
    # The form should show just the name part, not the full copyright text
    copyright_field = find(COPYRIGHT_INPUT)
    puts "Field shows with year format: #{copyright_field.value.inspect}"
    
    # Change to new value
    fill_in "site_settings[copyright]", with: "新しい会社名"
    click_button "設定を保存"
    
    assert_equal "新しい会社名", SiteSetting.copyright
    assert_equal "新しい会社名", find(COPYRIGHT_INPUT).value
  end

  test "multiple back-to-back copyright changes" do
    SiteSetting.set('copyright', '最初の値')
    
    login_as_admin(@admin)
    visit admin_site_settings_path
    
    # First change
    fill_in "site_settings[copyright]", with: "2番目の値"
    click_button "設定を保存"
    assert_equal "2番目の値", SiteSetting.copyright
    
    # Second change immediately after
    fill_in "site_settings[copyright]", with: "3番目の値" 
    click_button "設定を保存"
    assert_equal "3番目の値", SiteSetting.copyright
    
    # Third change
    fill_in "site_settings[copyright]", with: "最終的な値"
    click_button "設定を保存"
    assert_equal "最終的な値", SiteSetting.copyright
    assert_equal "最終的な値", find(COPYRIGHT_INPUT).value
  end

  test "copyright change with page navigation in between" do
    SiteSetting.set('copyright', '初期値')
    
    login_as_admin(@admin)
    
    # Go to settings
    visit admin_site_settings_path
    fill_in "site_settings[copyright]", with: "中間値"
    click_button "設定を保存"
    
    # Navigate away and back
    visit admin_articles_path
    visit admin_site_settings_path
    
    # Verify value persisted
    assert_equal "中間値", find(COPYRIGHT_INPUT).value
    
    # Change again
    fill_in "site_settings[copyright]", with: "最終値"
    click_button "設定を保存"
    
    assert_equal "最終値", SiteSetting.copyright
    assert_equal "最終値", find(COPYRIGHT_INPUT).value
  end

  test "copyright change with special characters and unicode" do
    SiteSetting.set('copyright', 'Plain Text')
    
    login_as_admin(@admin)
    visit admin_site_settings_path
    
    # Test with Japanese characters
    japanese_text = "株式会社テスト"
    fill_in "site_settings[copyright]", with: japanese_text
    click_button "設定を保存"
    assert_equal japanese_text, SiteSetting.copyright
    
    # Test with symbols and numbers
    mixed_text = "Company™ 2025"
    fill_in "site_settings[copyright]", with: mixed_text
    click_button "設定を保存"
    assert_equal mixed_text, SiteSetting.copyright
    
    # Test with emojis
    emoji_text = "会社名 🏢"
    fill_in "site_settings[copyright]", with: emoji_text
    click_button "設定を保存"
    assert_equal emoji_text, SiteSetting.copyright
  end

  test "verify footer display updates immediately after copyright change" do
    SiteSetting.set('copyright', '古いフッター名')
    
    login_as_admin(@admin)
    visit admin_site_settings_path
    
    # Change copyright
    new_name = "新しいフッター名"
    fill_in "site_settings[copyright]", with: new_name
    click_button "設定を保存"
    
    # Go to public page and check footer
    visit root_path
    expected_footer = "© #{Date.current.year} #{new_name}. All rights reserved."
    assert_selector "footer small", text: expected_footer
  end
end