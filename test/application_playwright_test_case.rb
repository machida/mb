require "test_helper"
require "playwright"
require "socket"
require_relative "support/selectors"

# Custom exception for Playwright setup failures
class PlaywrightSetupError < StandardError; end

class ApplicationPlaywrightTestCase < ActiveSupport::TestCase
  # Disable parallel execution for Playwright tests to avoid database conflicts
  parallelize(workers: 1)
  
  # Disable transactional fixtures for system tests to avoid transaction isolation issues
  self.use_transactional_tests = false
  
  include TestSelectors

  def setup
    super
    
    # Skip Playwright tests in CI if environment variable is set
    if ENV['SKIP_PLAYWRIGHT_TESTS'] == 'true'
      skip "Playwright tests skipped in CI environment"
    end
    
    # Clear all data before test starts to ensure clean state
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
    
    setup_rails_server
    setup_playwright
  end

  def teardown
    teardown_playwright
    teardown_rails_server
    super
    
    # Minimal cleanup in teardown - just clear cache to avoid interference
    Rails.cache.clear
  end

  # Playwright setup and teardown
  def setup_playwright
    max_retries = 3
    retry_count = 0
    
    begin
      Rails.logger.info "Setting up Playwright (attempt #{retry_count + 1}/#{max_retries})"
      
      # Create Playwright instance without block for persistent use
      if ENV['CI'] || ENV['GITHUB_ACTIONS']
        @playwright = Playwright.create
        @browser = @playwright.playwright.chromium.launch(
          headless: true,
          args: ['--no-sandbox', '--disable-dev-shm-usage'] # CI-friendly arguments
        )
      else
        @playwright = Playwright.create(playwright_cli_executable_path: find_playwright_executable)
        @browser = @playwright.playwright.chromium.launch(headless: true)
      end
      @context = @browser.new_context
      @page = @context.new_page
      
      Rails.logger.info "Playwright setup completed successfully"
      
    rescue => e
      retry_count += 1
      
      # Log the specific error for debugging
      Rails.logger.error "Playwright setup failed (attempt #{retry_count}/#{max_retries}): #{e.class.name} - #{e.message}"
      
      # Clean up any partial initialization
      cleanup_partial_playwright_setup
      
      if retry_count < max_retries
        # Wait before retrying, with exponential backoff
        sleep_time = retry_count * 2
        Rails.logger.info "Retrying Playwright setup in #{sleep_time} seconds..."
        sleep(sleep_time)
        retry
      else
        # After max retries, raise a more descriptive error
        raise PlaywrightSetupError, 
              "Failed to initialize Playwright after #{max_retries} attempts. " \
              "Last error: #{e.class.name} - #{e.message}. " \
              "This is a known issue with playwright-ruby-client. " \
              "Consider using Capybara tests instead."
      end
    end
  end
  
  def teardown_playwright
    cleanup_partial_playwright_setup
  end
  
  # Helper method to safely clean up partial Playwright initialization
  def cleanup_partial_playwright_setup
    begin
      @page&.close
    rescue => e
      Rails.logger.debug "Error closing Playwright page: #{e.message}"
    end
    
    begin
      @context&.close  
    rescue => e
      Rails.logger.debug "Error closing Playwright context: #{e.message}"
    end
    
    begin
      @browser&.close
    rescue => e
      Rails.logger.debug "Error closing Playwright browser: #{e.message}"
    end
    
    begin
      @playwright&.stop
    rescue => e
      Rails.logger.debug "Error stopping Playwright: #{e.message}"
    end
    
    # Clear instance variables
    @page = nil
    @context = nil
    @browser = nil
    @playwright = nil
  end

  # Rails server management
  def setup_rails_server
    @server_port = find_available_port
    
    # In CI environment, use different server setup
    if ENV['CI'] || ENV['GITHUB_ACTIONS']
      # Use a different approach for CI with more verbose logging
      @server_pid = spawn("rails", "server", "-p", @server_port.to_s, "-e", "test")
      wait_for_server_ready(timeout: 60) # Longer timeout for CI
    else
      @server_pid = spawn("rails", "server", "-p", @server_port.to_s, "-e", "test", 
                          out: "/dev/null", err: "/dev/null")
      wait_for_server_ready
    end
  end
  
  def teardown_rails_server
    if @server_pid
      begin
        Process.kill("TERM", @server_pid)
        Process.wait(@server_pid)
      rescue Errno::ESRCH
        # Process already dead
      rescue => e
        Rails.logger.debug "Error terminating Rails server: #{e.message}"
      end
    end
  end

  # Helper methods for common test actions
  def login_as_admin(admin = nil)
    admin ||= create_admin
    # Ensure admin was created successfully
    Rails.logger.debug "Created admin: #{admin.inspect}" if Rails.logger.debug?
    @page.goto("http://localhost:#{@server_port}/admin/login")
    
    # Wait for the page to load completely
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for login form elements to be available
    @page.wait_for_selector(LOGIN_EMAIL_INPUT, timeout: 10000)
    @page.wait_for_selector(LOGIN_PASSWORD_INPUT, timeout: 10000)
    @page.wait_for_selector(LOGIN_BUTTON, timeout: 10000)
    
    @page.fill(LOGIN_EMAIL_INPUT, admin.email)
    @page.fill(LOGIN_PASSWORD_INPUT, TEST_ADMIN_PASSWORD)
    @page.click(LOGIN_BUTTON)
    
    # Wait for successful login - either redirect to home or stay if already at intended page
    begin
      @page.wait_for_url("http://localhost:#{@server_port}/", timeout: 5000)
    rescue Playwright::TimeoutError
      # If redirect doesn't happen, check if we're already on the right page or login was successful
      @page.wait_for_load_state(state: 'networkidle')
    end
    
    # Verify login was successful by checking for admin content or lack of login form
    if @page.url.include?('admin/login')
      # Still on login page, login likely failed
      page_text = @page.text_content("body")
      assert false, "Login failed. Page content: #{page_text}"
    end
    
    admin
  end

  def create_admin(attributes = {})
    # Clean up any existing admin with same email/user_id to avoid conflicts
    existing_admin = Admin.find_by(email: TEST_ADMIN_EMAIL) || Admin.find_by(user_id: TEST_ADMIN_USER_ID)
    existing_admin&.destroy
    
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
  
  private
  
  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close
    port
  end
  
  def wait_for_server_ready(timeout: 30)
    max_retries = timeout * 10 # 0.1 second intervals
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
    Rails.logger.debug "Searching for Playwright executable..."
    
    # Try npx first (most common in Node.js projects)
    if system("which npx > /dev/null 2>&1")
      Rails.logger.debug "Found npx, using 'npx playwright'"
      return "npx playwright"
    end
    
    # Try direct executable (global installation)
    if system("which playwright > /dev/null 2>&1")
      Rails.logger.debug "Found direct playwright executable"
      return "playwright"
    end
    
    # Check if playwright is installed via npm in project
    if File.exist?("node_modules/.bin/playwright")
      Rails.logger.debug "Found playwright in node_modules/.bin/"
      return "./node_modules/.bin/playwright"
    end
    
    # Fallback error with helpful message
    error_msg = "Playwright executable not found. Please install Playwright:\n" \
                "  npm install -g @playwright/test\n" \
                "  npx playwright install\n" \
                "Or install locally: npm install @playwright/test"
    
    Rails.logger.error error_msg
    raise PlaywrightSetupError, error_msg
  end
end