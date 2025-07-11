require "test_helper"
require_relative "support/selectors"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  
  include TestSelectors

  # Common test helper methods
  def login_as_admin(admin = nil)
    admin ||= create_admin
    visit admin_login_path
    find(LOGIN_EMAIL_INPUT).fill_in with: admin.email
    find(LOGIN_PASSWORD_INPUT).fill_in with: "password123"
    find(LOGIN_BUTTON).click
    
    # Wait for successful login and redirect
    assert_current_path root_path
    assert_text "ログインしました"
    admin
  end

  def create_admin(attributes = {})
    default_attributes = {
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
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
end
