require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Clean up existing data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
    
    @published_article = Article.create!(
      title: "Published Article",
      body: "Published content",
      summary: "Published summary",
      author: @admin.user_id,
      draft: false
    )
    
    @draft_article = Article.create!(
      title: "Draft Article",
      body: "Draft content",
      summary: "Draft summary", 
      author: @admin.user_id,
      draft: true
    )
  end

  test "should get index" do
    get root_path
    assert_response :success
    assert_select "h1", "マチダのブログ"
  end

  test "index should only show published articles" do
    get root_path
    assert_response :success
    
    # Check that only published articles are shown
    assert_select "h2 a", text: @published_article.title
    assert_no_match @draft_article.title, response.body
    
    # Check that only one article is shown (the published one)
    assert_select "article", count: 1
  end

  test "should show published article" do
    get article_path(@published_article)
    assert_response :success
    assert_select "h1", @published_article.title
    assert_select ".markdown-body"
  end

  test "should show archive year" do
    get archive_year_path(@published_article.created_at.year)
    assert_response :success
    assert_select "h1", "#{@published_article.created_at.year}年の記事"
  end

  test "should show archive month" do
    get archive_month_path(@published_article.created_at.year, @published_article.created_at.month)
    assert_response :success
    assert_select "h1", "#{@published_article.created_at.year}年#{@published_article.created_at.month}月の記事"
  end

  test "archive should only show published articles" do
    get archive_year_path(@published_article.created_at.year)
    assert_response :success
    
    assert_match @published_article.title, response.body
    assert_no_match @draft_article.title, response.body
  end

  test "should show login link when not logged in" do
    get root_path
    assert_response :success
    assert_select "a[href=?]", admin_login_path, text: "ログイン"
  end

  test "should show admin links when logged in" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get root_path
    assert_response :success
    assert_select "a[href=?]", admin_articles_path, text: "記事管理"
    assert_select "a[href=?]", admin_logout_path, text: "ログアウト"
  end
end
