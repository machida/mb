require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  def setup
    # Clear test data
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
      body: "# Published Content\n\nThis is published content with **bold** text.",
      summary: "Published summary",
      author: @admin.user_id,
      draft: false
    )
    
    @draft_article = Article.create!(
      title: "Draft Article",
      body: "# Draft Content\n\nThis is draft content.",
      summary: "Draft summary",
      author: @admin.user_id,
      draft: true
    )
  end

  test "visiting the index" do
    visit root_path
    
    assert_selector ".spec-main-title", text: "マチダのブログ"
    assert_selector ".spec-article-item", count: 1
    assert_selector ".spec-article-title a", text: @published_article.title
    assert_no_selector ".spec-article-title a", text: @draft_article.title
  end

  test "reading a published article" do
    visit root_path
    click_on @published_article.title
    
    assert_selector ".spec-article-title", text: @published_article.title
    assert_selector ".spec-article-content h1", text: "Published Content"
    assert_selector ".spec-article-content strong", text: "bold"
    assert_text @published_article.summary
  end

  test "admin login and article management" do
    visit admin_login_path
    
    fill_in "メールアドレス", with: @admin.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
    
    assert_current_path root_path
    assert_selector ".toast-notification", text: "ログインしました"
    
    find(".spec-admin-link").click
    assert_current_path admin_articles_path
    
    # Check draft and published articles are shown separately
    assert_selector ".spec-draft-section-title", text: "下書き記事"
    assert_selector ".spec-published-section-title", text: "公開記事"
  end

  test "creating a new article" do
    login_as_admin
    
    visit admin_articles_path
    find(".spec-new-article-link").click
    
    find(".spec-title-input").fill_in with: "New Test Article"
    find(".spec-summary-input").fill_in with: "Test summary"
    find(".spec-body-input").fill_in with: "# Test Heading\n\nThis is test content."
    
    # Wait for preview to load
    assert_selector "[data-markdown-preview-target='preview'] h1", text: "Test Heading"
    
    find(".spec-publish-button").click
    
    assert_selector ".toast-notification", text: "記事を公開しました"
    
    # Check the article was created
    article = Article.last
    assert_equal "New Test Article", article.title
    assert_not article.draft?
  end

  test "creating a draft article" do
    login_as_admin
    
    visit new_admin_article_path
    
    find(".spec-title-input").fill_in with: "Draft Test Article"
    find(".spec-body-input").fill_in with: "Draft content"
    
    find(".spec-draft-button").click
    
    assert_current_path admin_articles_path
    assert_selector ".toast-notification", text: "下書きを保存しました"
    
    # Check the article was created as draft
    article = Article.last
    assert_equal "Draft Test Article", article.title
    assert article.draft?
  end

  test "editing an article" do
    login_as_admin
    
    visit admin_articles_path
    
    # Find the published article and click edit
    within ".spec-published-articles-list" do
      click_on "編集"
    end
    
    find(".spec-title-input").fill_in with: "Updated Title"
    find(".spec-body-input").fill_in with: "# Updated Content\n\nThis is updated."
    
    click_button "更新"
    
    assert_selector ".toast-notification", text: "記事を公開しました"
    
    @published_article.reload
    assert_equal "Updated Title", @published_article.title
  end

  test "deleting an article" do
    login_as_admin
    
    visit admin_articles_path
    
    # Accept the confirmation dialog
    accept_confirm do
      click_on "削除"
    end
    
    assert_selector ".toast-notification", text: "Article was successfully deleted"
    assert_no_selector ".spec-published-article-title", text: @published_article.title
  end

  test "archive navigation" do
    visit archive_year_path(@published_article.created_at.year)
    
    assert_selector ".spec-archive-year-title", text: "#{@published_article.created_at.year}年の記事"
    assert_selector "article", count: 1
    
    # Click on month archive
    click_on "#{@published_article.created_at.month}月"
    
    assert_selector ".spec-archive-month-title", text: "#{@published_article.created_at.year}年#{@published_article.created_at.month}月の記事"
    assert_selector "article", count: 1
  end

  private

  def login_as_admin
    visit admin_login_path
    find(".spec-email-input").fill_in with: @admin.email
    find(".spec-password-input").fill_in with: "password123"
    find(".spec-login-button").click
  end
end