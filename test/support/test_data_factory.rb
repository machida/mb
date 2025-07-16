module TestDataFactory
  # Admin factory methods
  def build_admin_attributes(attributes = {})
    {
      email: "test#{rand(1000)}@example.com",
      user_id: "test_admin_#{rand(1000)}",
      password: "password123",
      password_confirmation: "password123"
    }.merge(attributes)
  end

  def create_admin_with_attributes(attributes = {})
    Admin.create!(build_admin_attributes(attributes))
  end

  def create_multiple_admins(count = 3)
    count.times.map do |i|
      create_admin_with_attributes(
        user_id: "admin_#{i + 1}",
        email: "admin#{i + 1}@example.com"
      )
    end
  end

  # Article factory methods
  def build_article_attributes(attributes = {})
    {
      title: "Test Article #{rand(1000)}",
      body: "# Test Content\n\nThis is test article content.",
      summary: "Test article summary",
      author: TestConfig::TEST_ADMIN_USER_ID,
      draft: false
    }.merge(attributes)
  end

  def create_article_with_attributes(attributes = {})
    Article.create!(build_article_attributes(attributes))
  end

  def create_published_articles(count = 3, author = nil)
    author ||= TestConfig::TEST_ADMIN_USER_ID
    count.times.map do |i|
      create_article_with_attributes(
        title: "Published Article #{i + 1}",
        author: author,
        draft: false
      )
    end
  end

  def create_draft_articles(count = 2, author = nil)
    author ||= TestConfig::TEST_ADMIN_USER_ID
    count.times.map do |i|
      create_article_with_attributes(
        title: "Draft Article #{i + 1}",
        author: author,
        draft: true
      )
    end
  end

  # Site setting factory methods
  def create_site_setting(name, value)
    SiteSetting.create!(name: name, value: value)
  end

  def create_default_site_settings
    {
      "site_title" => "Test Blog",
      "copyright" => "Test Copyright",
      "top_page_description" => "Test Description",
      "default_og_image" => "https://example.com/default.jpg"
    }.each do |name, value|
      create_site_setting(name, value)
    end
  end

  # Test scenario builders
  def setup_admin_management_scenario
    {
      main_admin: create_test_admin,
      other_admins: create_multiple_admins(2),
      articles: create_published_articles(3)
    }
  end

  def setup_article_management_scenario
    admin = create_test_admin
    {
      admin: admin,
      published_articles: create_published_articles(3, admin.user_id),
      draft_articles: create_draft_articles(2, admin.user_id)
    }
  end
end