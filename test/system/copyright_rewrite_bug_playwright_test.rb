require "application_playwright_test_case"

class CopyrightRewriteBugPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
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
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    
    # Verify current state
    current_db_value = SiteSetting.copyright
    Rails.logger.info "Current copyright value in DB: #{current_db_value}"
    
    # Check current form value
    copyright_field = @page.query_selector(COPYRIGHT_INPUT)
    current_value = copyright_field.input_value
    Rails.logger.info "Current form value: #{current_value.inspect}"
    
    # Change to a completely different value
    new_value = "新しい会社名"
    @page.fill("input[name='site_settings[copyright]']", new_value)
    
    # Submit the form
    @page.click("button:has-text('設定を保存')")
    
    # Wait for form submission and redirect
    @page.wait_for_url(/.*\/admin\/site_settings/)
    
    # Wait for any async operations to complete
    @page.wait_for_load_state('networkidle')
    
    # Force cache clearing
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
    # Direct database query without any caching
    updated_db_value = ActiveRecord::Base.connection.exec_query(
      "SELECT value FROM site_settings WHERE name = ?",
      "SQL",
      ["copyright"]
    ).first&.fetch("value")
    
    Rails.logger.info "Direct SQL query result: #{updated_db_value.inspect}"
    
    # Also check through the model
    model_value = SiteSetting.copyright
    Rails.logger.info "Model value: #{model_value.inspect}"
    
    # Check form field value after save
    copyright_field_after = @page.query_selector(COPYRIGHT_INPUT)
    form_value_after = copyright_field_after.input_value
    
    # Assertions
    assert_equal new_value, updated_db_value, "Database should be updated"
    assert_equal new_value, form_value_after, "Form should show updated value"
  end

  test "debug copyright update request parameters" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    
    # Use Playwright's network monitoring instead of execute_script
    @page.on('request') do |request|
      if request.method == 'PATCH' && request.url.include?('site_settings')
        Rails.logger.info "Request URL: #{request.url}"
        Rails.logger.info "Request method: #{request.method}"
        Rails.logger.info "Request headers: #{request.headers}"
        
        # Log form data if available
        if request.post_data
          Rails.logger.info "Request body: #{request.post_data}"
        end
      end
    end
    
    # Fill in new copyright
    @page.fill("input[name='site_settings[copyright]']", "デバッグテスト")
    
    # Submit and wait for completion
    @page.click("button:has-text('設定を保存')")
    @page.wait_for_url(/.*\/admin\/site_settings/)
    @page.wait_for_load_state('networkidle')
    
    # Check final result using direct database access
    final_value = get_current_copyright
    Rails.logger.info "Final copyright value: #{final_value.inspect}"
    
    assert_equal "デバッグテスト", final_value
  end

  test "step by step copyright change process" do
    login_as_admin(@admin)
    
    # Step 1: Record initial state
    initial_value = get_current_copyright
    Rails.logger.info "Step 1 - Initial copyright: #{initial_value.inspect}"
    
    # Step 2: Visit settings page
    @page.goto("http://localhost:#{@server_port}/admin/site_settings")
    Rails.logger.info "Step 2 - Visited settings page"
    
    # Step 3: Check form displays correct initial value
    copyright_field = @page.query_selector(COPYRIGHT_INPUT)
    form_initial_value = copyright_field.input_value
    Rails.logger.info "Step 3 - Form shows: #{form_initial_value.inspect}"
    assert_equal initial_value, form_initial_value, "Form should show current value"
    
    # Step 4: Clear and enter new value
    new_value = "段階的テスト著作権者"
    @page.fill("input[name='site_settings[copyright]']", "")  # Clear first
    @page.fill("input[name='site_settings[copyright]']", new_value)
    Rails.logger.info "Step 4 - Entered new value: #{new_value.inspect}"
    
    # Step 5: Verify field contains new value before submit
    field_before_submit = @page.query_selector(COPYRIGHT_INPUT).input_value
    Rails.logger.info "Step 5 - Field before submit: #{field_before_submit.inspect}"
    assert_equal new_value, field_before_submit, "Field should contain new value before submit"
    
    # Step 6: Submit form
    @page.click("button:has-text('設定を保存')")
    Rails.logger.info "Step 6 - Submitted form"
    
    # Step 7: Verify we're on settings page and wait for completion
    @page.wait_for_url(/.*\/admin\/site_settings/)
    Rails.logger.info "Step 7 - Confirmed redirect"
    
    # Check for any success or error messages
    alert_element = @page.query_selector('.alert')
    if alert_element
      Rails.logger.info "Alert message: #{alert_element.inner_text}"
    end
    
    notice_element = @page.query_selector('.notice')
    if notice_element
      Rails.logger.info "Notice message: #{notice_element.inner_text}"
    end
    
    # Wait for any async operations and force cache clearing
    @page.wait_for_load_state('networkidle')
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
    # Step 8: Check database value using direct database access
    db_value_after = get_current_copyright
    Rails.logger.info "Step 8 - DB value after submit: #{db_value_after.inspect}"
    
    # Step 9: Check form field value after redirect
    copyright_field_after = @page.query_selector(COPYRIGHT_INPUT)
    form_value_after = copyright_field_after.input_value
    Rails.logger.info "Step 9 - Form value after redirect: #{form_value_after.inspect}"
    
    # Final assertions
    assert_equal new_value, db_value_after, "Database should contain new value"
    assert_equal new_value, form_value_after, "Form should display new value after save"
  end
end