require "test_helper"

class ArticlesShowTest < ActionDispatch::IntegrationTest
  def setup
    Admin.destroy_all
    Article.destroy_all
    SiteSetting.destroy_all

    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should use article thumbnail as og:image when present" do
    article = Article.create!(
      title: "Test Article",
      body: "Test content",
      summary: "Test summary",
      author: @admin.user_id,
      thumbnail: "https://example.com/article-thumbnail.jpg"
    )

    get article_path(article)
    assert_response :success
    assert_select "meta[property='og:image'][content='https://example.com/article-thumbnail.jpg']"
  end

  test "should use default og:image when article has no thumbnail" do
    SiteSetting.set('default_og_image', 'https://example.com/default-og.jpg')
    
    article = Article.create!(
      title: "Test Article",
      body: "Test content",
      summary: "Test summary",
      author: @admin.user_id,
      thumbnail: nil
    )

    get article_path(article)
    assert_response :success
    assert_select "meta[property='og:image'][content='https://example.com/default-og.jpg']"
  end

  test "should not have og:image when neither thumbnail nor default og:image is set" do
    article = Article.create!(
      title: "Test Article",
      body: "Test content",
      summary: "Test summary",
      author: @admin.user_id,
      thumbnail: nil
    )

    get article_path(article)
    assert_response :success
    assert_select "meta[property='og:image']", count: 0
  end

  test "should use default og:image on top page" do
    SiteSetting.set('default_og_image', 'https://example.com/default-og.jpg')
    
    get root_path
    assert_response :success
    assert_select "meta[property='og:image'][content='https://example.com/default-og.jpg']"
  end

  test "should not have og:image on top page when default og:image is not set" do
    get root_path
    assert_response :success
    assert_select "meta[property='og:image']", count: 0
  end
end