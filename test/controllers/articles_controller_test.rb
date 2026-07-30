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
    assert_select ".spec--main-title", "マチダのブログ"
    assert_select ".l--public-header__brand a[href=?]", root_path, text: "machida"
    assert_select ".l--public-header__links" do
      assert_select ".l--public-header__nav:nth-child(1)[aria-label='ABOUT']" do
        assert_select ".l--public-header__icon", "person"
      end
      assert_select ".l--public-header__nav:nth-child(2)[aria-label='ARCHIVE']" do
        assert_select ".l--public-header__icon", "calendar_month"
      end
    end
    assert_select ".l--public-header__inner.is--home", count: 1
    assert_select ".a--hero.has-background[style*='retro-hawaii-hero']", count: 1
    assert_select ".l--footer small", "© #{Date.current.year} @machida"
  end

  test "index should only show published articles" do
    @published_article.update!(thumbnail: "https://example.com/thumbnail.jpg")

    get root_path
    assert_response :success
    
    # Check that only published articles are shown
    assert_select ".spec--article-title", text: @published_article.title
    assert_no_match @draft_article.title, response.body
    
    # Check that only one article is shown (the published one)
    assert_select ".spec--article-item", count: 1
    assert_select ".spec--article-thumbnail-link[href=?]", article_path(@published_article), count: 1
    assert_select ".spec--article-thumbnail-link .l--article-item__image-original", count: 1
    assert_select ".spec--article-thumbnail-link .l--article-item__image-sepia", count: 1
    assert_select ".l--article-item__more", count: 0
  end

  test "should show published article" do
    @published_article.update!(thumbnail: "https://example.com/article.jpg")

    get article_path(@published_article)
    assert_response :success
    assert_select ".spec--article-title", @published_article.title
    assert_select ".spec--article-content"
    assert_select ".l--article-page"
    assert_select ".l--article-main > .l--article-main__image:first-child", count: 1
    assert_select ".l--public-header__inner.is--home", count: 0
    assert_select ".l--article-sidebar", count: 0
  end

  test "should show previous and next article links for published article" do
    Article.destroy_all

    older_article = Article.create!(
      title: "Older Article",
      body: "Older content",
      summary: "Older summary",
      author: @admin.user_id,
      draft: false,
      created_at: 2.days.ago
    )

    current_article = Article.create!(
      title: "Current Article",
      body: "Current content",
      summary: "Current summary",
      author: @admin.user_id,
      draft: false,
      created_at: 1.day.ago
    )

    newer_article = Article.create!(
      title: "Newer Article",
      body: "Newer content",
      summary: "Newer summary",
      author: @admin.user_id,
      draft: false,
      created_at: Time.current
    )

    get article_path(current_article)
    assert_response :success
    assert_select ".spec--previous-article-link[href=?]", article_path(newer_article), text: "前の記事"
    assert_select ".spec--next-article-link[href=?]", article_path(older_article), text: "次の記事"
    assert_equal "← PREV\n#{newer_article.title}", css_select(".spec--previous-article-link").first["data-label"]
    assert_equal "NEXT →\n#{older_article.title}", css_select(".spec--next-article-link").first["data-label"]
  end

  test "should hide previous article link on newest article" do
    Article.destroy_all

    older_article = Article.create!(
      title: "Older Article",
      body: "Older content",
      summary: "Older summary",
      author: @admin.user_id,
      draft: false,
      created_at: 2.days.ago
    )

    newer_article = Article.create!(
      title: "Newer Article",
      body: "Newer content",
      summary: "Newer summary",
      author: @admin.user_id,
      draft: false,
      created_at: Time.current
    )

    get article_path(newer_article)
    assert_response :success
    assert_select ".spec--previous-article-link", count: 0
    assert_select ".spec--next-article-link[href=?]", article_path(older_article), text: "次の記事"
  end

  test "should hide next article link on oldest article" do
    Article.destroy_all

    older_article = Article.create!(
      title: "Older Article",
      body: "Older content",
      summary: "Older summary",
      author: @admin.user_id,
      draft: false,
      created_at: 2.days.ago
    )

    newer_article = Article.create!(
      title: "Newer Article",
      body: "Newer content",
      summary: "Newer summary",
      author: @admin.user_id,
      draft: false,
      created_at: Time.current
    )

    get article_path(older_article)
    assert_response :success
    assert_select ".spec--previous-article-link[href=?]", article_path(newer_article), text: "前の記事"
    assert_select ".spec--next-article-link", count: 0
  end

  test "should not link draft articles from published article navigation" do
    Article.destroy_all

    older_article = Article.create!(
      title: "Older Article",
      body: "Older content",
      summary: "Older summary",
      author: @admin.user_id,
      draft: false,
      created_at: 2.days.ago
    )

    draft_article = Article.create!(
      title: "Draft Middle Article",
      body: "Draft content",
      summary: "Draft summary",
      author: @admin.user_id,
      draft: true,
      created_at: 1.day.ago
    )

    newer_article = Article.create!(
      title: "Newer Article",
      body: "Newer content",
      summary: "Newer summary",
      author: @admin.user_id,
      draft: false,
      created_at: Time.current
    )

    get article_path(older_article)
    assert_response :success
    assert_select ".spec--previous-article-link[href=?]", article_path(newer_article), text: "前の記事"
    assert_no_match article_path(draft_article), response.body
  end

  test "should show archive year" do
    get archive_year_path(@published_article.created_at.year)
    assert_response :success
    assert_select ".spec--archive-year-title", "#{@published_article.created_at.year}年の記事"
  end

  test "should show archive month" do
    get archive_month_path(@published_article.created_at.year, @published_article.created_at.month)
    assert_response :success
    assert_select ".spec--archive-month-title", "#{@published_article.created_at.year}年#{@published_article.created_at.month}月の記事"
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
    assert_select "form[action=?]", admin_logout_path
  end

  test "should not access draft article when not logged in" do
    get article_path(@draft_article)
    assert_redirected_to root_path
    follow_redirect!
    assert_match "この記事は非公開です。", response.body
  end

  test "should access draft article when logged in as admin" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get article_path(@draft_article)
    assert_response :success
    assert_select ".spec--article-title", @draft_article.title
    assert_select ".spec--article-content"
  end

  test "should show draft notification for draft articles when logged in as admin" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get article_path(@draft_article)
    assert_response :success
    assert_select ".spec--draft-notice", text: /この記事は下書きです/
    assert_select ".spec--draft-notice", text: /一般には公開されていません/
  end

  test "should not show draft notification for published articles" do
    get article_path(@published_article)
    assert_response :success
    assert_select ".spec--draft-notice", count: 0
  end

  test "should include noindex robots meta tag for draft articles" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get article_path(@draft_article)
    assert_response :success
    assert_select "meta[name='robots'][content='noindex, nofollow']"
  end

  test "should not include robots meta tag for published articles" do
    get article_path(@published_article)
    assert_response :success
    assert_select "meta[name='robots'][content='noindex, nofollow']", count: 0
  end

  test "should show delete button on article page when logged in as admin" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }
    
    get article_path(@published_article)
    assert_response :success
    assert_select ".spec--delete-article-button", text: "削除"
  end

  test "should not show delete button on article page when not logged in" do
    get article_path(@published_article)
    assert_response :success
    assert_select ".spec--delete-article-button", count: 0
  end

  test "should return 404 for invalid year in archive" do
    get archive_year_path(0)
    assert_response :not_found
  end

  test "should return 404 for invalid month in archive" do
    get archive_month_path(2024, 0)
    assert_response :not_found

    get archive_month_path(2024, 13)
    assert_response :not_found
  end

  test "published article link should point to show page in public" do
    get root_path

    # 公開画面では記事詳細ページへのリンクを指すべき
    assert_select "a[href=?]", article_path(@published_article)
  end

  test "should get RSS feed" do
    get feed_path(format: :rss)
    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", response.content_type
    assert_match @published_article.title, response.body
    assert_no_match @draft_article.title, response.body
  end
end
