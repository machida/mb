# test/support/system_test_case.rb  
# システムテスト（E2Eテスト）用の基底クラス
class SystemTestCase < ApplicationTestCase
  include PlaywrightHelpers
  include TestSelectors
  include TestCategories
  
  category :system
  tags :e2e, :playwright, :system
  
  # トランザクションを無効化（システムテストでは別プロセスのため）
  self.use_transactional_tests = false if respond_to?(:use_transactional_tests=)
  
  def setup
    super
    
    # CI環境でのスキップ設定
    if TestConfiguration.ci_config[:skip_playwright_tests]
      skip "Playwright tests skipped in CI environment"
    end
    
    # システムテスト用の徹底的なデータクリーンアップ
    cleanup_system_test_data
    create_default_site_settings
    
    # Playwright環境のセットアップ
    setup_playwright_environment
  end
  
  def teardown
    teardown_playwright_environment
    super
  end
  
  protected
  
  # システムテスト用のデータクリーンアップ
  def cleanup_system_test_data
    # より徹底的なクリーンアップ（別プロセスのため）
    Admin.delete_all
    Article.delete_all
    SiteSetting.delete_all
    Rails.cache.clear
  end
  
  # デフォルトのサイト設定を作成
  def create_default_site_settings
    SiteSetting.create!([
      { name: "site_title", value: "マチダのブログ" },
      { name: "copyright", value: "マチダのブログ" },
      { name: "top_page_description", value: "マチダのブログへようこそ" },
      { name: "default_og_image", value: "https://example.com/default-og-image.jpg" }
    ])
  end
  
  # Playwright環境のセットアップ
  def setup_playwright_environment
    max_retries = 3
    retry_count = 0
    
    begin
      Rails.logger.info "Setting up Playwright (attempt #{retry_count + 1}/#{max_retries})"
      
      if ci_environment?
        setup_ci_playwright
      else
        setup_local_playwright
      end
      
      @context = @browser.new_context
      @page = @context.new_page
      
      Rails.logger.info "Playwright setup completed successfully"
      
    rescue => e
      retry_count += 1
      
      Rails.logger.error "Playwright setup failed (attempt #{retry_count}/#{max_retries}): #{e.class.name} - #{e.message}"
      
      cleanup_partial_playwright_setup
      
      if retry_count < max_retries
        sleep_time = retry_count * 2
        Rails.logger.info "Retrying Playwright setup in #{sleep_time} seconds..."
        sleep(sleep_time)
        retry
      else
        raise PlaywrightSetupError, 
              "Failed to initialize Playwright after #{max_retries} attempts. " \
              "Last error: #{e.class.name} - #{e.message}"
      end
    end
  end
  
  # Playwright環境のティアダウン
  def teardown_playwright_environment
    cleanup_partial_playwright_setup
  end
  
  # ページの完全な読み込み待機
  def wait_for_page_ready
    @page.wait_for_load_state('networkidle')
    @page.wait_for_function('document.readyState === "complete"')
  end
  
  # エラー時のスクリーンショット取得
  def capture_screenshot_on_failure
    return unless @page
    
    screenshot_path = "tmp/screenshots/#{self.class.name}_#{@NAME}.png"
    FileUtils.mkdir_p(File.dirname(screenshot_path))
    @page.screenshot(path: screenshot_path)
    puts "Screenshot saved: #{screenshot_path}"
  end
  
  private
  
  def ci_environment?
    TestConfiguration.ci_config[:is_ci]
  end
  
  def setup_ci_playwright
    config = TestConfiguration.playwright_config
    @playwright = Playwright.create
    @browser = @playwright.playwright.chromium.launch(
      headless: config[:headless],
      args: ['--no-sandbox', '--disable-dev-shm-usage']
    )
  end
  
  def setup_local_playwright
    config = TestConfiguration.playwright_config
    @playwright = Playwright.create(playwright_cli_executable_path: find_playwright_executable)
    @browser = @playwright.playwright.chromium.launch(
      headless: config[:headless]
    )
  end
  
  def cleanup_partial_playwright_setup
    [@page, @context, @browser, @playwright].each do |resource|
      next unless resource
      
      begin
        case resource
        when @page then resource.close
        when @context then resource.close  
        when @browser then resource.close
        when @playwright then resource.stop
        end
      rescue => e
        Rails.logger.debug "Error cleaning up Playwright resource: #{e.message}"
      end
    end
    
    @page = @context = @browser = @playwright = nil
  end
  
  def find_playwright_executable
    Rails.logger.debug "Searching for Playwright executable..."
    
    if system("which npx > /dev/null 2>&1")
      Rails.logger.debug "Found npx, using 'npx playwright'"
      return "npx playwright"
    end
    
    if system("which playwright > /dev/null 2>&1")
      Rails.logger.debug "Found direct playwright executable"
      return "playwright"
    end
    
    if File.exist?("node_modules/.bin/playwright")
      Rails.logger.debug "Found playwright in node_modules/.bin/"
      return "./node_modules/.bin/playwright"
    end
    
    error_msg = "Playwright executable not found. Please install Playwright"
    Rails.logger.error error_msg
    raise PlaywrightSetupError, error_msg
  end
end