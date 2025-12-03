require "test_helper"

class ArticleServiceTest < ActiveSupport::TestCase
  def setup
    @admin = Admin.create!(email: "test@example.com", password: "password123", user_id: "testadmin")
    @article = Article.create!(
      title: "テスト記事",
      body: "# テストヘッダー\n\nこれはテスト本文です。",
      author: @admin,
      draft: true
    )
    @service = ArticleService.new(@article)
  end

  test "should initialize with article" do
    assert_equal @article, @service.article
  end

  test "og_image_url returns article thumbnail when present" do
    @article.update!(thumbnail: "https://example.com/thumbnail.jpg")
    assert_equal "https://example.com/thumbnail.jpg", @service.og_image_url
  end

  test "og_image_url returns default OG image when article has no thumbnail" do
    @article.update!(thumbnail: nil)
    SiteSetting.set("default_og_image", "https://example.com/default_og.jpg")

    assert_equal "https://example.com/default_og.jpg", @service.og_image_url
  end

  test "og_image_url returns nil when no thumbnail and no default" do
    @article.update!(thumbnail: nil)
    SiteSetting.set("default_og_image", "")

    assert_nil @service.og_image_url
  end

  test "formatted_body returns body content" do
    assert_equal @article.body, @service.formatted_body
  end

  test "formatted_body returns empty string when body is blank" do
    # body is required, so create a new service with an article that has minimal body
    article_with_minimal_body = Article.new(
      title: "Test",
      body: "",
      author: @admin
    )
    service = ArticleService.new(article_with_minimal_body)
    assert_equal "", service.formatted_body
  end

  test "summary_for_display returns article summary when present" do
    @article.update!(summary: "これはサマリーです")
    assert_equal "これはサマリーです", @service.summary_for_display
  end

  test "summary_for_display generates from body when summary is blank" do
    @article.update!(summary: nil, body: "# ヘッダー\nこれは本文です。長い本文が続きます。" * 10)
    summary = @service.summary_for_display

    assert summary.present?
    assert summary.length <= 153 # truncate(150) + "..."
    assert_not summary.start_with?("#") # ヘッダーマーカーは削除される
  end

  test "publish! should set draft to false" do
    assert @article.draft
    @service.publish!
    assert_not @article.reload.draft
  end

  test "unpublish! should set draft to true" do
    @article.update!(draft: false)
    assert_not @article.draft

    @service.unpublish!
    assert @article.reload.draft
  end

  test "create_article should create article" do
    params = {
      title: "新しい記事",
      body: "新しい本文",
      draft: true
    }

    article = ArticleService.create_article(params, @admin)

    assert article.persisted?
    assert_equal "新しい記事", article.title
    assert_equal "新しい本文", article.body
  end

  test "create_article should return nil when validation fails" do
    params = {
      title: "", # 必須項目が空
      body: "本文"
    }

    article = ArticleService.create_article(params, @admin)
    assert_nil article
  end
end
