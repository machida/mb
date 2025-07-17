require "test_helper"

class Admin::ArticlesControllerTest < IntegrationTestCase
  def setup
    clear_test_data
    
    @admin = create_admin
    @article = create_article(author: @admin.user_id)
    @draft_article = create_draft_article(author: @admin.user_id)
  end

  test "should redirect to login when not authenticated" do
    get admin_articles_path
    assert_redirect_to_login
  end

  test "should get index when authenticated" do
    login_as_admin(@admin)
    get admin_articles_path
    assert_success_response
    assert_select ".spec--article-index-title", "全ての記事"
    # Check that both articles are displayed
    assert_select ".spec--articles-list > article", count: 2
  end

  test "should get drafts page" do
    login_as_admin(@admin)
    get drafts_admin_articles_path
    assert_success_response
    assert_select ".spec--draft-index-title", "下書き記事"
    # Check that only draft article is displayed
    assert_select ".spec--draft-articles-list > article", count: 1
  end

  test "should get new when authenticated" do
    login_as_admin(@admin)
    get new_admin_article_path
    assert_success_response
    assert_select ".spec--new-article-title", "新しい記事を作成"
  end

  test "should create article as published" do
    login_as_admin(@admin)
    
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
    login_as_admin(@admin)
    
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
    login_as_admin(@admin)
    get edit_admin_article_path(@article)
    assert_success_response
    assert_select ".spec--edit-article-title", "記事を編集"
  end

  test "should update article" do
    login_as_admin(@admin)
    
    patch admin_article_path(@article), params: {
      article: {
        title: "Updated Title",
        body: "Updated content"
      }
    }
    
    @article.reload
    assert_article_attributes(@article, title: "Updated Title", body: "Updated content")
  end

  test "should destroy article" do
    login_as_admin(@admin)
    
    assert_difference('Article.count', -1) do
      delete admin_article_path(@article)
    end
    
    assert_redirected_to admin_articles_path
  end

  test "should generate preview" do
    login_as_admin(@admin)
    
    post admin_articles_preview_path, params: { content: "# Test Heading" }
    assert_success_response
    
    assert_json_response(
      expected_keys: ['html'],
      should_include: { 'html' => '<h1' }
    )
  end

  test "should upload image" do
    login_as_admin(@admin)
    
    test_image = create_test_image
    
    post admin_articles_upload_image_path, params: { image: test_image[:uploaded_file] }
    assert_success_response
    
    assert_json_response(
      expected_keys: ['url', 'markdown'],
      should_include: { 'markdown' => '![画像]' }
    )
  ensure
    test_image[:temp_file]&.unlink
  end

  test "should reject non-image upload" do
    login_as_admin(@admin)
    
    file = Rack::Test::UploadedFile.new(
      StringIO.new("not an image"),
      "text/plain",
      original_filename: "test.txt"
    )
    
    post admin_articles_upload_image_path, params: { image: file }
    assert_response :unprocessable_entity
    
    json_response = assert_json_response(expected_keys: ['error'])
    assert_equal "画像ファイルのみアップロード可能です", json_response['error']
  end
end