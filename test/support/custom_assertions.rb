module CustomAssertions
  # Form validation assertions
  def assert_form_has_errors(form_selector = ".spec--admin-form")
    assert_select "#{form_selector} .bg-red-50", minimum: 1, 
                  message: "Expected form to display validation errors"
  end

  def assert_form_has_no_errors(form_selector = ".spec--admin-form")
    assert_select "#{form_selector} .bg-red-50", count: 0,
                  message: "Expected form to have no validation errors"
  end

  def assert_required_field_error(field_name)
    assert_select ".bg-red-50", text: /#{field_name}.*required|#{field_name}.*空|#{field_name}.*入力/i,
                  message: "Expected required field error for #{field_name}"
  end

  # Navigation and UI assertions
  def assert_admin_navigation_present
    assert_select ".spec--admin-management-link", 
                  message: "Expected admin management link in navigation"
    assert_select ".spec--dropdown-button",
                  message: "Expected dropdown button in navigation"
  end

  def assert_redirect_to_login
    assert_redirected_to admin_login_path,
                        message: "Expected redirect to admin login page"
  end

  # Data presence assertions
  def assert_admin_count(expected_count)
    actual_count = Admin.count
    assert_equal expected_count, actual_count,
                "Expected #{expected_count} admins, but found #{actual_count}"
  end

  def assert_admin_exists(attributes)
    admin = Admin.find_by(attributes)
    assert admin, "Expected admin with attributes #{attributes} to exist"
    admin
  end

  def assert_admin_does_not_exist(attributes)
    admin = Admin.find_by(attributes)
    assert_nil admin, "Expected admin with attributes #{attributes} to not exist"
  end

  # Response and content assertions
  def assert_success_response_with_content(expected_content)
    assert_response :success
    assert_includes response.body, expected_content,
                   "Expected response to contain: #{expected_content}"
  end

  def assert_unauthorized_access(path, method = :get, params = {})
    case method
    when :get
      get path, params: params
    when :post  
      post path, params: params
    when :patch
      patch path, params: params
    when :delete
      delete path, params: params
    end

    assert_redirect_to_login
  end

  # Security assertions
  def assert_cannot_delete_self(current_admin_selector = ".spec--admin-item")
    # Should not show delete button for current admin
    current_admin_item = css_select("#{current_admin_selector}").first
    assert current_admin_item, "Expected to find current admin item"
    
    delete_buttons = css_select("#{current_admin_selector} .spec--delete-admin-btn")
    assert_empty delete_buttons, "Expected no delete button for current admin"
  end

  def assert_admin_session_required(path_method, *args)
    # Test without login
    get send(path_method, *args)
    assert_redirect_to_login
  end

  # Database transaction assertions
  def assert_no_database_changes(&block)
    admin_count_before = Admin.count
    article_count_before = Article.count
    
    yield
    
    assert_equal admin_count_before, Admin.count, "Expected no change in admin count"
    assert_equal article_count_before, Article.count, "Expected no change in article count"
  end
end