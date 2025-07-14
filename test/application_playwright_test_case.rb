require "test_helper"
require "playwright"
require "socket"
require_relative "support/selectors"

class ApplicationPlaywrightTestCase < ActiveSupport::TestCase
  # Disable transactional fixtures for system tests to avoid transaction isolation issues
  self.use_transactional_tests = false
  
  include TestSelectors

  def setup
    super
    setup_rails_server
    setup_playwright
  end

  def teardown
    teardown_playwright
    teardown_rails_server
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

  # Playwright setup and teardown
  def setup_playwright
    @playwright = Playwright.create(
      playwright_cli_executable_path: find_playwright_executable
    )
    # Launch browser without arguments first
    @browser = @playwright.playwright.chromium.launch
    @context = @browser.new_context
    @page = @context.new_page
  end
  
  def teardown_playwright
    @page&.close
    @context&.close
    @browser&.close
    @playwright&.stop
  end

  # Rails server management
  def setup_rails_server
    @server_port = find_available_port
    @server_pid = spawn("rails", "server", "-p", @server_port.to_s, "-e", "test", 
                        out: "/dev/null", err: "/dev/null")
    wait_for_server_ready
  end
  
  def teardown_rails_server
    Process.kill("TERM", @server_pid) if @server_pid
    Process.wait(@server_pid) if @server_pid
  rescue
    # Ignore errors if process is already dead
  end

  # Helper methods for common test actions
  def login_as_admin(admin = nil)
    admin ||= create_admin
    @page.goto("http://localhost:#{@server_port}/admin/login")
    
    @page.fill(LOGIN_EMAIL_INPUT, admin.email)
    @page.fill(LOGIN_PASSWORD_INPUT, "password123")
    @page.click(LOGIN_BUTTON)
    
    # Wait for successful login and redirect
    @page.wait_for_url("http://localhost:#{@server_port}/")
    assert @page.text_content("body").include?("ログインしました")
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
  
  private
  
  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close
    port
  end
  
  def wait_for_server_ready
    max_retries = 30
    retries = 0
    
    loop do
      begin
        TCPSocket.new('127.0.0.1', @server_port).close
        break
      rescue Errno::ECONNREFUSED
        retries += 1
        if retries >= max_retries
          raise "Rails server failed to start on port #{@server_port}"
        end
        sleep 0.1
      end
    end
  end
  
  def find_playwright_executable
    # Try npx first
    return "npx playwright" if system("which npx > /dev/null 2>&1")
    
    # Try direct executable
    return "playwright" if system("which playwright > /dev/null 2>&1")
    
    # Fallback
    raise "Playwright executable not found. Please install with 'npm install -g @playwright/test'"
  end
end