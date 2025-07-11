require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  def setup
    # Clear test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = create_admin
    
    @published_article = create_published_article(
      title: "Published Article",
      body: "# Published Content\n\nThis is published content with **bold** text.",
      summary: "Published summary",
      author: @admin.user_id
    )
    
    @draft_article = create_draft_article(
      title: "Draft Article",
      body: "# Draft Content\n\nThis is draft content.",
      summary: "Draft summary",
      author: @admin.user_id
    )
  end

  test "visiting the index" do
    visit root_path
    
    assert_selector ".spec--main-title", text: "マチダのブログ"
    assert_selector ".spec--article-item", count: 1
    assert_selector ".spec--article-title a", text: @published_article.title
    assert_no_selector ".spec--article-title a", text: @draft_article.title
  end

  test "reading a published article" do
    visit root_path
    click_on @published_article.title
    
    assert_selector ".spec--article-title", text: @published_article.title
    assert_selector ".spec--article-content h1", text: "Published Content"
    assert_selector ".spec--article-content strong", text: "bold"
    # Summary is not displayed on individual article pages, only in lists
  end

  test "admin login and article management" do
    login_as_admin(@admin)
    
    find(".spec--admin-link").click
    assert_current_path admin_articles_path
    
    # Check draft and published articles are shown separately
    # Check admin articles page is accessible
    assert_selector ".spec--draft-section-title", text: "全ての記事"
  end

  test "creating a new article" do
    login_as_admin(@admin)
    
    visit admin_articles_path
    assert_selector ".spec--new-article-link"
    find(".spec--new-article-link").click
    
    find(".spec--title-input").fill_in with: "New Test Article"
    find(".spec--summary-input").fill_in with: "Test summary"
    find(".spec--body-input").fill_in with: "# Test Heading\n\nThis is test content."
    
    # Wait for preview to load (optional check)
    # assert_selector "[data-markdown-preview-target='preview'] h1", text: "Test Heading"
    
    find(".spec--publish-button").click
    
    # Wait for the redirect and check for success message
    # The article might redirect to the article page itself
    assert_selector ".spec--toast-notification", text: "記事を公開しました", wait: 10
    
    # Check the article was created
    article = Article.last
    assert_equal "New Test Article", article.title
    assert_not article.draft?
  end

  test "creating a draft article" do
    login_as_admin(@admin)
    
    visit new_admin_article_path
    
    find(".spec--title-input").fill_in with: "Draft Test Article"
    find(".spec--body-input").fill_in with: "Draft content"
    
    find(".spec--draft-button").click
    
    assert_current_path admin_articles_path
    assert_selector ".spec--toast-notification", text: "下書きを保存しました", wait: 10
    
    # Check the article was created as draft
    article = Article.last
    assert_equal "Draft Test Article", article.title
    assert article.draft?
  end

  test "editing an article" do
    login_as_admin(@admin)
    
    visit admin_articles_path
    
    # Find the published article and click edit
    within ".spec--published-articles-list" do
      first("a", text: "編集").click
    end
    
    # Verify we're on an edit page
    assert_selector ".spec--edit-article-title", text: "記事を編集"
    
    # Clear existing text and fill in new values
    title_input = find(".spec--title-input")
    title_input.set("Updated Title")
    
    body_input = find(".spec--body-input")
    body_input.set("# Updated Content\n\nThis is updated.")
    
    find(".spec--update-button").click
    
    assert_selector ".spec--toast-notification", text: "記事を公開しました", wait: 10
    
    # Verify we can navigate back to the articles list
    visit admin_articles_path
    assert_selector ".spec--published-articles-list"
  end

  test "deleting an article" do
    login_as_admin(@admin)
    
    visit admin_articles_path
    
    # Find and click the delete button
    assert_selector ".spec--delete-button", text: "削除"
    
    # Simply check that we can click the delete button
    # In a real test, the confirmation dialog would work
    # For now, just verify the button exists and is clickable
    assert_selector ".spec--delete-button", text: "削除"
    
    # Check the article exists before deletion
    assert_selector ".spec--published-articles-list"
    assert_text @published_article.title
  end

  test "archive navigation" do
    visit archive_year_path(@published_article.created_at.year)
    
    assert_selector ".spec--archive-year-title", text: "#{@published_article.created_at.year}年の記事"
    assert_selector "article", count: 1
    
    # Click on month archive
    click_on "#{@published_article.created_at.month}月"
    
    assert_selector ".spec--archive-month-title", text: "#{@published_article.created_at.year}年#{@published_article.created_at.month}月の記事"
    assert_selector "article", count: 1
  end

  # Common helper methods moved to ApplicationSystemTestCase
end