require "application_system_test_case"

class CopyrightRewriteBugTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
    
    # Set initial copyright value
    SiteSetting.set('copyright', 'マチダのブログ')
  end

  test "can actually change copyright holder name from existing value to new value" do
    login_as_admin(@admin)
    
    # Go to site settings
    visit admin_site_settings_path
    
    # Verify current state
    puts "Current copyright value in DB: #{SiteSetting.copyright}"
    
    # Check current form value
    copyright_field = find(COPYRIGHT_INPUT)
    current_value = copyright_field.value
    puts "Current form value: #{current_value.inspect}"
    
    # Change to a completely different value
    new_value = "新しい会社名"
    fill_in "site_settings[copyright]", with: new_value
    
    # Submit the form
    click_button "設定を保存"
    
    # Check if we're redirected properly
    assert_current_path admin_site_settings_path
    
    # Wait a bit for any async operations to complete
    sleep 0.5
    
    # Force a new database connection and bypass all caching
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
    # Direct database query without any caching
    updated_db_value = ActiveRecord::Base.connection.exec_query(
      "SELECT value FROM site_settings WHERE name = 'copyright'"
    ).first&.fetch("value")
    
    puts "Direct SQL query result: #{updated_db_value.inspect}"
    
    # Also check through the model
    model_value = SiteSetting.copyright
    puts "Model value: #{model_value.inspect}"
    
    # Check form field value after save
    copyright_field_after = find(COPYRIGHT_INPUT)
    form_value_after = copyright_field_after.value
    
    # Assertions
    assert_equal new_value, updated_db_value, "Database should be updated"
    assert_equal new_value, form_value_after, "Form should show updated value"
  end

  test "debug copyright update request parameters" do
    login_as_admin(@admin)
    
    visit admin_site_settings_path
    
    # Use JavaScript to inspect what gets sent
    page.execute_script("""
      const form = document.querySelector('form');
      const originalSubmit = form.submit;
      form.addEventListener('submit', function(e) {
        const formData = new FormData(form);
        console.log('Form data being submitted:');
        for (let [key, value] of formData.entries()) {
          console.log(key + ': ' + value);
        }
      });
    """)
    
    # Fill in new copyright
    fill_in "site_settings[copyright]", with: "デバッグテスト"
    
    # Submit and capture any JavaScript console logs
    click_button "設定を保存"
    
    # Give some time for any async operations
    sleep 1
    
    # Check final result using direct database access
    final_value = get_current_copyright
    puts "Final copyright value: #{final_value.inspect}"
    
    assert_equal "デバッグテスト", final_value
  end

  test "step by step copyright change process" do
    login_as_admin(@admin)
    
    # Step 1: Record initial state
    initial_value = get_current_copyright
    puts "Step 1 - Initial copyright: #{initial_value.inspect}"
    
    # Step 2: Visit settings page
    visit admin_site_settings_path
    puts "Step 2 - Visited settings page"
    
    # Step 3: Check form displays correct initial value
    copyright_field = find(COPYRIGHT_INPUT)
    form_initial_value = copyright_field.value
    puts "Step 3 - Form shows: #{form_initial_value.inspect}"
    assert_equal initial_value, form_initial_value, "Form should show current value"
    
    # Step 4: Clear and enter new value
    fill_in "site_settings[copyright]", with: ""  # Clear first
    new_value = "段階的テスト著作権者"
    fill_in "site_settings[copyright]", with: new_value
    puts "Step 4 - Entered new value: #{new_value.inspect}"
    
    # Step 5: Verify field contains new value before submit
    field_before_submit = find(COPYRIGHT_INPUT).value
    puts "Step 5 - Field before submit: #{field_before_submit.inspect}"
    assert_equal new_value, field_before_submit, "Field should contain new value before submit"
    
    # Step 6: Submit form
    click_button "設定を保存"
    puts "Step 6 - Submitted form"
    
    # Step 7: Verify we're on settings page
    assert_current_path admin_site_settings_path
    puts "Step 7 - Confirmed redirect"
    
    # Check for any success or error messages
    if page.has_css?('.alert')
      puts "Alert message: #{find('.alert').text}"
    end
    if page.has_css?('.notice') 
      puts "Notice message: #{find('.notice').text}"
    end
    
    # Add extra wait and force cache clearing
    sleep 1
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
    # Step 8: Check database value using direct database access
    db_value_after = get_current_copyright
    puts "Step 8 - DB value after submit: #{db_value_after.inspect}"
    
    # Step 9: Check form field value after redirect
    copyright_field_after = find(COPYRIGHT_INPUT)
    form_value_after = copyright_field_after.value
    puts "Step 9 - Form value after redirect: #{form_value_after.inspect}"
    
    # Final assertions
    assert_equal new_value, db_value_after, "Database should contain new value"
    assert_equal new_value, form_value_after, "Form should display new value after save"
  end
end