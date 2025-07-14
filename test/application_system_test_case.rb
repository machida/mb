require "test_helper"
require_relative "support/selectors"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  
  # Disable transactional fixtures for system tests to avoid transaction isolation issues
  self.use_transactional_tests = false
  
  include TestSelectors

  # Clean up database after each test since we're not using transactions
  def teardown
    super
    # Clear all data except fixtures/seeds that should persist
    Admin.where.not(email: "admin@example.com").delete_all
    Article.delete_all
    SiteSetting.delete_all
    
    # Reset default settings
    SiteSetting.create!(name: "site_title", value: "マチダのブログ")
    SiteSetting.create!(name: "copyright", value: "マチダのブログ")
    SiteSetting.create!(name: "top_page_description", value: "マチダのブログへようこそ")
    SiteSetting.create!(name: "default_og_image", value: "https://example.com/default-og-image.jpg")
    
    # Clear cache
    Rails.cache.clear
  end

  # Common test helper methods
  def login_as_admin(admin = nil)
    admin ||= create_admin
    visit admin_login_path
    find(LOGIN_EMAIL_INPUT).fill_in with: admin.email
    find(LOGIN_PASSWORD_INPUT).fill_in with: TEST_ADMIN_PASSWORD
    find(LOGIN_BUTTON).click
    
    # Wait for successful login and redirect
    assert_current_path root_path
    assert_text "ログインしました"
    admin
  end

  def create_admin(attributes = {})
    default_attributes = {
      email: TEST_ADMIN_EMAIL,
      user_id: TEST_ADMIN_USER_ID,
      password: TEST_ADMIN_PASSWORD,
      password_confirmation: TEST_ADMIN_PASSWORD
    }
    Admin.create!(default_attributes.merge(attributes))
  end

  def create_article(attributes = {})
    default_attributes = {
      title: "Test Article",
      body: "# Test Content\n\nThis is test content.",
      summary: "Test summary",
      draft: false
    }
    Article.create!(default_attributes.merge(attributes))
  end

  def create_draft_article(attributes = {})
    create_article(attributes.merge(draft: true))
  end

  def create_published_article(attributes = {})
    create_article(attributes.merge(draft: false))
  end

  # Helper method to get current copyright value with proper cache clearing
  def get_current_copyright
    # Force a new database connection and bypass all caching
    ActiveRecord::Base.connection.clear_query_cache
    Rails.cache.clear
    
    # Direct database query without any caching - using parameterized query for security
    ActiveRecord::Base.connection.exec_query(
      "SELECT value FROM site_settings WHERE name = ?",
      "SQL",
      ["copyright"]
    ).first&.fetch("value") || "マチダのブログ"
  end
end
