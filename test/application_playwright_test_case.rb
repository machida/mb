require "test_helper"
require "playwright"
require "socket"
require_relative "support/selectors"

# Custom exception for Playwright setup failures
class PlaywrightSetupError < StandardError; end

class ApplicationPlaywrightTestCase < SystemTestCase
  def setup
    super
    setup_rails_server
  end

  def teardown
    teardown_rails_server
    super
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

  # Helper method for Playwright-specific admin login
  def login_as_admin_playwright(admin = nil)
    admin ||= create_admin
    @page.goto("http://localhost:#{@server_port}/admin/login")
    
    @page.fill(LOGIN_EMAIL_INPUT, admin.email)
    @page.fill(LOGIN_PASSWORD_INPUT, TestConfig::TEST_ADMIN_PASSWORD)
    @page.click(LOGIN_BUTTON)
    
    # Wait for successful login and redirect
    @page.wait_for_url("http://localhost:#{@server_port}/")
    assert @page.text_content("body").include?("ログインしました")
    admin
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