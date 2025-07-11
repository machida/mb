require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  def setup
    @admin = Admin.create!(
      email: "test@example.com",
      user_id: "testuser",
      password: "password123",
      password_confirmation: "password123"
    )
    @article = Article.new(
      title: "Test Article",
      body: "This is a test article",
      summary: "Test summary",
      author: @admin.user_id
    )
  end

  test "should be valid with valid attributes" do
    assert @article.valid?
  end

  test "should require title" do
    @article.title = nil
    assert_not @article.valid?
    assert_includes @article.errors[:title], "can't be blank"
  end

  test "should require body" do
    @article.body = nil
    assert_not @article.valid?
    assert_includes @article.errors[:body], "can't be blank"
  end

  test "should require author" do
    @article.author = nil
    assert_not @article.valid?
    assert_includes @article.errors[:author], "can't be blank"
  end

  test "should belong to admin" do
    @article.save!
    assert_equal @admin, @article.admin
  end

  test "should have default draft as false" do
    @article.save!
    assert_not @article.draft?
    assert @article.published?
  end

  test "should be able to set as draft" do
    @article.draft = true
    @article.save!
    assert @article.draft?
    assert_not @article.published?
  end

  test "published scope should return only published articles" do
    published_article = Article.create!(
      title: "Published Article",
      body: "Published content",
      author: @admin.user_id,
      draft: false
    )
    
    draft_article = Article.create!(
      title: "Draft Article", 
      body: "Draft content",
      author: @admin.user_id,
      draft: true
    )

    published_articles = Article.published
    assert_includes published_articles, published_article
    assert_not_includes published_articles, draft_article
  end

  test "drafts scope should return only draft articles" do
    published_article = Article.create!(
      title: "Published Article",
      body: "Published content", 
      author: @admin.user_id,
      draft: false
    )
    
    draft_article = Article.create!(
      title: "Draft Article",
      body: "Draft content",
      author: @admin.user_id,
      draft: true
    )

    draft_articles = Article.drafts
    assert_includes draft_articles, draft_article
    assert_not_includes draft_articles, published_article
  end

  test "og_image_url should return thumbnail when present" do
    @article.thumbnail = "https://example.com/thumbnail.jpg"
    @article.save!
    
    assert_equal "https://example.com/thumbnail.jpg", @article.og_image_url
  end

  test "og_image_url should return default og image when thumbnail not present" do
    SiteSetting.set("default_og_image", "https://example.com/default.jpg")
    @article.thumbnail = nil
    @article.save!
    
    assert_equal "https://example.com/default.jpg", @article.og_image_url
  end

  test "og_image_url should return nil when neither thumbnail nor default og image present" do
    # Clear default_og_image setting by removing it entirely
    SiteSetting.find_by(name: "default_og_image")&.destroy
    @article.thumbnail = nil
    @article.save!
    
    assert_nil @article.og_image_url
  end

  test "should allow blank summary" do
    @article.summary = ""
    assert @article.valid?
    
    @article.summary = nil
    assert @article.valid?
  end

  test "should allow blank thumbnail" do
    @article.thumbnail = ""
    assert @article.valid?
    
    @article.thumbnail = nil
    assert @article.valid?
  end

  test "should handle long title and body" do
    @article.title = "A" * 1000
    @article.body = "B" * 10000
    assert @article.valid?
  end

  test "published? and draft? should be opposite" do
    @article.draft = false
    assert @article.published?
    assert_not @article.draft?
    
    @article.draft = true
    assert_not @article.published?
    assert @article.draft?
  end

  test "should handle author with special characters" do
    @article.author = "user-123_test"
    assert @article.valid?
  end
end
