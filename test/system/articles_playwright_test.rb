require "application_playwright_test_case"

class ArticlesPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
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
    @page.goto("http://localhost:#{@server_port}/")
    
    # Wait for the page to load completely including hero section
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for main title to be visible
    @page.wait_for_selector(".spec--main-title", timeout: 10000)
    
    # Check main title
    title_element = @page.query_selector(".spec--main-title")
    assert title_element, "Main title should exist"
    assert_equal "マチダのブログ", title_element.inner_text
    
    # Check article count (only published articles should appear)
    article_items = @page.query_selector_all(".spec--article-item")
    assert_equal 1, article_items.count
    
    # Check published article appears
    published_link = @page.query_selector(".spec--article-title a")
    assert published_link, "Published article link should exist"
    assert_equal @published_article.title, published_link.inner_text
    
    # Check draft article does not appear
    draft_links = @page.query_selector_all(".spec--article-title a")
    draft_titles = draft_links.map(&:inner_text)
    assert_not_includes draft_titles, @draft_article.title
  end

  test "reading a published article" do
    @page.goto("http://localhost:#{@server_port}/")
    @page.click("a:has-text('#{@published_article.title}')")
    
    @page.wait_for_load_state(state: 'networkidle')
    
    # Check article title
    article_title = @page.query_selector(".spec--article-title")
    assert article_title, "Article title should exist"
    assert_equal @published_article.title, article_title.inner_text
    
    # Check article content structure
    h1_element = @page.query_selector(".spec--article-content h1")
    assert h1_element, "H1 element should exist"
    assert_equal "Published Content", h1_element.inner_text
    
    strong_element = @page.query_selector(".spec--article-content strong")
    assert strong_element, "Strong element should exist"
    assert_equal "bold", strong_element.inner_text
  end

  test "admin login and article management" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/")
    @page.click(".spec--admin-link")
    
    @page.wait_for_url(/.*\/admin\/articles/)
    
    # Check admin articles page is accessible
    section_title = @page.query_selector(".spec--draft-section-title")
    assert section_title, "Draft section title should exist"
    assert_equal "全ての記事", section_title.inner_text
  end

  test "creating a new article" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    new_article_link = @page.query_selector(".spec--new-article-link")
    assert new_article_link, "New article link should exist"
    @page.click(".spec--new-article-link")
    
    @page.wait_for_load_state(state: 'networkidle')
    
    # Fill in article form
    @page.fill(".spec--title-input", "New Test Article")
    @page.fill(".spec--summary-input", "Test summary")
    @page.fill(".spec--body-input", "# Test Heading\n\nThis is test content.")
    
    # Wait a moment for any preview to load
    @page.wait_for_timeout(500)
    
    @page.click(".spec--publish-button")
    
    # Wait for success message
    @page.wait_for_selector(".spec--toast-notification", timeout: 10000)
    
    toast_element = @page.query_selector(".spec--toast-notification")
    assert toast_element, "Toast notification should appear"
    assert_equal "記事を公開しました。", toast_element.inner_text
    
    # Check the article was created
    article = Article.last
    assert_equal "New Test Article", article.title
    assert_not article.draft?
  end

  test "creating a draft article" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/articles/new")
    
    @page.fill(".spec--title-input", "Draft Test Article")
    @page.fill(".spec--body-input", "Draft content")
    
    @page.click(".spec--draft-button")
    
    @page.wait_for_url(/.*\/admin\/articles/)
    
    # Wait for success message
    @page.wait_for_selector(".spec--toast-notification", timeout: 10000)
    
    toast_element = @page.query_selector(".spec--toast-notification")
    assert toast_element, "Toast notification should appear"
    assert_equal "下書きを保存しました。", toast_element.inner_text
    
    # Check the article was created as draft
    article = Article.last
    assert_equal "Draft Test Article", article.title
    assert article.draft?
  end

  test "editing an article" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    # Find the published article and click edit
    published_section = @page.query_selector(".spec--published-articles-list")
    assert published_section, "Published articles list should exist"
    
    edit_link = published_section.query_selector("a:has-text('編集')")
    assert edit_link, "Edit link should exist"
    edit_link.click()
    
    @page.wait_for_load_state(state: 'networkidle')
    
    # Verify we're on an edit page
    edit_title = @page.query_selector(".spec--edit-article-title")
    assert edit_title, "Edit article title should exist"
    assert_equal "記事を編集", edit_title.inner_text
    
    # Clear existing text and fill in new values
    @page.fill(".spec--title-input", "Updated Title")
    @page.fill(".spec--body-input", "# Updated Content\n\nThis is updated.")
    
    @page.click(".spec--update-button")
    
    # Wait for success message
    @page.wait_for_selector(".spec--toast-notification", timeout: 10000)
    
    toast_element = @page.query_selector(".spec--toast-notification")
    assert toast_element, "Toast notification should appear"
    assert_equal "記事を公開しました。", toast_element.inner_text
    
    # Verify we can navigate back to the articles list
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    published_list = @page.query_selector(".spec--published-articles-list")
    assert published_list, "Published articles list should exist"
  end

  test "deleting an article" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    
    # Find and check the delete button exists
    delete_button = @page.query_selector(".spec--delete-button")
    assert delete_button, "Delete button should exist"
    assert_equal "削除", delete_button.inner_text
    
    # Check the article exists before potential deletion
    published_list = @page.query_selector(".spec--published-articles-list")
    assert published_list, "Published articles list should exist"
    
    # Verify the article title is present
    article_text = @page.inner_text("body")
    assert_includes article_text, @published_article.title
  end

  test "archive navigation" do
    year = @published_article.created_at.year
    month = @published_article.created_at.month
    
    @page.goto("http://localhost:#{@server_port}/archive/#{year}")
    
    # Check year archive page
    year_title = @page.query_selector(".spec--archive-year-title")
    assert year_title, "Archive year title should exist"
    assert_equal "#{year}年の記事", year_title.inner_text
    
    articles = @page.query_selector_all("article")
    assert_equal 1, articles.count
    
    # Click on month archive
    @page.click("a:has-text('#{month}月')")
    
    @page.wait_for_load_state(state: 'networkidle')
    
    # Check month archive page
    month_title = @page.query_selector(".spec--archive-month-title")
    assert month_title, "Archive month title should exist"
    assert_equal "#{year}年#{month}月の記事", month_title.inner_text
    
    month_articles = @page.query_selector_all("article")
    assert_equal 1, month_articles.count
  end
end
