# test/support/assertion_helpers.rb
module AssertionHelpers
  # Article assertions
  def assert_article_attributes(article, expected_attributes)
    expected_attributes.each do |key, value|
      assert_equal value, article.public_send(key), "Expected #{key} to be #{value}, got #{article.public_send(key)}"
    end
  end

  def assert_article_count(expected_count, message = nil)
    actual_count = Article.count
    assert_equal expected_count, actual_count, message || "Expected #{expected_count} articles, got #{actual_count}"
  end

  def assert_admin_count(expected_count, message = nil)
    actual_count = Admin.count
    assert_equal expected_count, actual_count, message || "Expected #{expected_count} admins, got #{actual_count}"
  end

  # Response assertions
  def assert_success_response(message = nil)
    assert_response :success, message || "Expected successful response"
  end

  def assert_redirect_to_login(message = nil)
    assert_redirected_to admin_login_path, message || "Expected redirect to login"
  end

  # JSON response assertions
  def assert_json_response(expected_keys: [], should_include: {}, should_not_include: [])
    json_response = JSON.parse(response.body)
    
    expected_keys.each do |key|
      assert json_response.key?(key), "Expected JSON response to have key: #{key}"
    end
    
    should_include.each do |key, value|
      assert_includes json_response[key], value, "Expected #{key} to include #{value}"
    end
    
    should_not_include.each do |key|
      assert_not json_response.key?(key), "Expected JSON response not to have key: #{key}"
    end
    
    json_response
  end

  # Error message assertions
  def assert_error_message(page: @page, selector: ".spec--error-messages", expected_text: nil)
    error_element = page.query_selector(selector)
    assert error_element, "Error messages should exist at #{selector}"
    
    if expected_text
      assert_includes error_element.inner_text, expected_text, "Expected error message to include: #{expected_text}"
    end
    
    error_element
  end

  def assert_success_message(page: @page, expected_text:)
    page_text = page.inner_text("body")
    assert_includes page_text, expected_text, "Expected success message: #{expected_text}"
  end

  # Element existence assertions
  def assert_element_exists(page: @page, selector:, message: nil)
    element = page.query_selector(selector)
    assert element, message || "Element should exist: #{selector}"
    element
  end

  def assert_element_not_exists(page: @page, selector:, message: nil)
    element = page.query_selector(selector)
    assert_nil element, message || "Element should not exist: #{selector}"
  end

  # Text content assertions
  def assert_page_contains(page: @page, text:, message: nil)
    page_text = page.inner_text("body")
    assert_includes page_text, text, message || "Expected page to contain: #{text}"
  end

  def assert_page_not_contains(page: @page, text:, message: nil)
    page_text = page.inner_text("body")
    assert_not_includes page_text, text, message || "Expected page not to contain: #{text}"
  end
end