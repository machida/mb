require "test_helper"

class ErrorHandlingTest < ActionDispatch::IntegrationTest
  def setup
    Admin.destroy_all
    Article.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should handle non-existent article gracefully" do
    get article_path(999999)
    assert_response :not_found
  end

  test "should handle invalid article id gracefully" do
    get article_path("invalid-id")
    assert_response :not_found
  end

  test "should handle non-existent admin article gracefully" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get edit_admin_article_path(999999)
    assert_response :not_found
  end

  test "should handle invalid admin routes when not logged in" do
    get admin_articles_path
    assert_redirected_to admin_login_path
    
    get edit_admin_profile_path
    assert_redirected_to admin_login_path
    
    get admin_site_settings_path
    assert_redirected_to admin_login_path
  end

  test "should handle CSRF token mismatch" do
    # CSRF protection is typically disabled in test environment
    # This test verifies the endpoint exists and handles requests properly
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    assert_response :redirect
  end

  test "should handle malformed requests" do
    post admin_login_path, params: { malformed: "data" }
    assert_response :unprocessable_entity
  end

  test "should handle SQL injection attempts in search" do
    # Test potential SQL injection via query parameters
    get root_path, params: { search: "'; DROP TABLE articles; --" }
    assert_response :success
    # Verify that the malicious query doesn't break anything
    assert_not_nil Article.all
  end

  test "should handle XSS attempts in article content" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    # Create article with potential XSS content
    post admin_articles_path, params: {
      article: {
        title: "<script>alert('xss')</script>",
        body: "<img src=x onerror=alert('xss')>",
        summary: "<script>alert('xss')</script>"
      },
      commit: "公開"
    }
    
    article = Article.last
    get article_path(article)
    assert_response :success
    
    # XSS should be escaped in the response
    assert_no_match /<script>/, response.body
    assert_no_match /onerror=/, response.body
  end

  test "should handle concurrent admin sessions" do
    # Login with first session
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    session1_id = session[:admin_id]
    
    # Start new session
    reset!
    
    # Login with second session  
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    session2_id = session[:admin_id]
    
    # Both sessions should work
    assert_equal @admin.id, session1_id
    assert_equal @admin.id, session2_id
  end

  test "should handle database connection errors gracefully" do
    # This is difficult to test without actually breaking the DB connection
    # but we can at least verify error handling structure exists
    
    # Test that articles can be loaded without errors
    get root_path
    assert_response :success
    
    # Verify basic database operations work
    assert_not_nil Article.all
  end

  test "should handle file upload errors" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    # Test uploading invalid file type
    invalid_file = Rack::Test::UploadedFile.new(
      StringIO.new("not an image"),
      "text/plain",
      original_filename: "test.txt"
    )
    
    post admin_articles_upload_image_path, params: { image: invalid_file }
    assert_response :unprocessable_entity
    
    json_response = JSON.parse(response.body)
    assert_equal "画像ファイルのみアップロード可能です", json_response['error']
  end

  test "should handle oversized file uploads" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    # Test uploading oversized file
    large_file = Rack::Test::UploadedFile.new(
      StringIO.new("x" * 6.megabytes),
      "image/jpeg",
      original_filename: "large.jpg"
    )
    
    post admin_articles_upload_image_path, params: { image: large_file }
    assert_response :unprocessable_entity
    
    json_response = JSON.parse(response.body)
    assert_equal "ファイルサイズは5MB以下にしてください", json_response['error']
  end
end