require "application_system_test_case"

class CopyrightUpdateTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
    
    # Reset copyright to known state
    SiteSetting.set('copyright', 'テスト著作権者')
  end

  test "admin can update copyright holder name" do
    login_as_admin(@admin)
    
    # Visit site settings page
    visit admin_site_settings_path
    
    # Verify current copyright value is displayed
    copyright_input = find(COPYRIGHT_INPUT)
    assert_equal "テスト著作権者", copyright_input.value
    
    # Update copyright holder name
    fill_in "site_settings[copyright]", with: "新しい著作権者名"
    
    # Save changes
    click_button "設定を保存"
    
    # Should be redirected back to settings page with success message
    assert_current_path admin_site_settings_path
    # Note: Toast notification testing is handled in other system tests
    
    # Verify the field shows updated value
    copyright_input = find(COPYRIGHT_INPUT)
    assert_equal "新しい著作権者名", copyright_input.value
    
    # Verify the setting was actually saved in the database
    assert_equal "新しい著作権者名", SiteSetting.copyright
  end

  test "admin can clear copyright holder name" do
    login_as_admin(@admin)
    
    # Visit site settings page
    visit admin_site_settings_path
    
    # Clear copyright field (empty string)
    fill_in "site_settings[copyright]", with: ""
    
    # Save changes
    click_button "設定を保存"
    
    # Should be redirected back to settings page
    assert_current_path admin_site_settings_path
    
    # Verify the field is empty
    copyright_input = find(COPYRIGHT_INPUT)
    assert_equal "", copyright_input.value
    
    # Verify the setting was actually cleared in the database
    assert_equal "", SiteSetting.copyright
  end

  test "admin can update copyright with whitespace that gets trimmed" do
    login_as_admin(@admin)
    
    # Visit site settings page
    visit admin_site_settings_path
    
    # Update copyright with leading/trailing spaces
    fill_in "site_settings[copyright]", with: "  スペース付き著作権者  "
    
    # Save changes
    click_button "設定を保存"
    
    # Should be redirected back to settings page
    assert_current_path admin_site_settings_path
    
    # Verify whitespace was trimmed in database
    assert_equal "スペース付き著作権者", SiteSetting.copyright
    
    # Note: Form field may still show spaces until page refresh
    # The important part is that database value is trimmed
  end

  test "copyright displays correctly in public layout after update" do
    login_as_admin(@admin)
    
    # Update copyright through admin interface
    visit admin_site_settings_path
    fill_in "site_settings[copyright]", with: "新しいブログ名"
    click_button "設定を保存"
    
    # Visit public page to verify copyright display
    visit root_path
    
    # Check that copyright is displayed with proper format in footer
    expected_text = "© #{Date.current.year} 新しいブログ名. All rights reserved."
    assert_selector "footer small", text: expected_text
  end

  test "copyright does not display in footer when empty" do
    login_as_admin(@admin)
    
    # Clear copyright through admin interface
    visit admin_site_settings_path
    fill_in "site_settings[copyright]", with: ""
    click_button "設定を保存"
    
    # Visit public page to verify no copyright display
    visit root_path
    
    # Check that no copyright text is displayed in footer
    assert_no_selector "footer small", text: /© #{Date.current.year}/
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