require "test_helper"

class Admin::ArticlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Clear all test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
    
    @article = Article.create!(
      title: "Test Article",
      body: "Test content",
      summary: "Test summary",
      author: @admin.user_id
    )
    
    @draft_article = Article.create!(
      title: "Draft Article",
      body: "Draft content",
      summary: "Draft summary",
      author: @admin.user_id,
      draft: true
    )
  end

  def login_as_admin
    post admin_login_path, params: { email: @admin.email, password: "password123" }
  end

  test "should redirect to login when not authenticated" do
    get admin_articles_path
    assert_redirected_to admin_login_path
  end

  test "should get index when authenticated" do
    login_as_admin
    get admin_articles_path
    assert_response :success
    assert_select ".spec--article-index-title", "全ての記事"
    # Check that both articles are displayed
    assert_select ".spec--articles-list > article", count: 2
  end

  test "should get drafts page" do
    login_as_admin
    get drafts_admin_articles_path
    assert_response :success
    assert_select ".spec--draft-index-title", "下書き記事"
    # Check that only draft article is displayed
    assert_select ".spec--draft-articles-list > article", count: 1
  end

  test "should get new when authenticated" do
    login_as_admin
    get new_admin_article_path
    assert_response :success
    assert_select ".spec--new-article-title", "新しい記事を作成"
  end

  test "should create article as published" do
    login_as_admin
    
    assert_difference('Article.count') do
      post admin_articles_path, params: {
        article: {
          title: "New Article",
          body: "New content",
          summary: "New summary"
        },
        commit: "公開"
      }
    end

    article = Article.last
    assert_not article.draft?
    assert_redirected_to article_path(article)
  end

  test "should create article as draft" do
    login_as_admin
    
    assert_difference('Article.count') do
      post admin_articles_path, params: {
        article: {
          title: "Draft Article",
          body: "Draft content", 
          summary: "Draft summary"
        },
        commit: "下書き保存"
      }
    end

    article = Article.last
    assert article.draft?
    assert_redirected_to admin_articles_path
  end

  test "should get edit when authenticated" do
    login_as_admin
    get edit_admin_article_path(@article)
    assert_response :success
    assert_select ".spec--edit-article-title", "記事を編集"
  end

  test "should update article" do
    login_as_admin
    
    patch admin_article_path(@article), params: {
      article: {
        title: "Updated Title",
        body: "Updated content"
      }
    }
    
    @article.reload
    assert_equal "Updated Title", @article.title
    assert_equal "Updated content", @article.body
  end

  test "should destroy article" do
    login_as_admin
    
    assert_difference('Article.count', -1) do
      delete admin_article_path(@article)
    end
    
    assert_redirected_to admin_articles_path
  end

  test "should generate preview" do
    login_as_admin
    
    post admin_articles_preview_path, params: { content: "# Test Heading" }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_includes json_response['html'], '<h1'
    assert_includes json_response['html'], 'Test Heading'
  end

  test "should upload image" do
    login_as_admin
    
    # VIPSで実際の画像を作成
    require "image_processing/vips"
    vips_image = Vips::Image.black(100, 100)
    temp_file = Tempfile.new([ "test_upload", ".jpg" ])
    temp_file.close
    vips_image.write_to_file(temp_file.path)
    
    image_data = File.binread(temp_file.path)
    image = Rack::Test::UploadedFile.new(
      StringIO.new(image_data),
      "image/jpeg",
      original_filename: "test.jpg"
    )
    
    post admin_articles_upload_image_path, params: { image: image }
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response['url']
    assert json_response['markdown']
    assert_includes json_response['markdown'], '![画像]'
  ensure
    temp_file&.unlink
  end

  test "should reject non-image upload" do
    login_as_admin
    
    file = Rack::Test::UploadedFile.new(
      StringIO.new("not an image"),
      "text/plain",
      original_filename: "test.txt"
    )
    
    post admin_articles_upload_image_path, params: { image: file }
    assert_response :unprocessable_entity
    
    json_response = JSON.parse(response.body)
    assert_equal "画像ファイルのみアップロード可能です", json_response['error']
  end
end