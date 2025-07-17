# test/support/test_configuration.rb
# テスト環境の設定管理
module TestConfiguration
  extend self
  
  # データベース設定
  def database_config
    @database_config ||= {
      cleanup_strategy: ENV.fetch('TEST_CLEANUP_STRATEGY', 'truncation'),
      parallel_workers: ENV.fetch('TEST_PARALLEL_WORKERS', 'auto'),
      connection_pool_size: ENV.fetch('TEST_DB_POOL_SIZE', 10).to_i
    }
  end
  
  # Playwright設定
  def playwright_config
    @playwright_config ||= {
      headless: ENV.fetch('PLAYWRIGHT_HEADLESS', 'true') == 'true',
      browser: ENV.fetch('PLAYWRIGHT_BROWSER', 'chromium'),
      timeout: ENV.fetch('PLAYWRIGHT_TIMEOUT', 30000).to_i,
      skip_install: ENV.fetch('SKIP_PLAYWRIGHT_INSTALL', 'false') == 'true'
    }
  end
  
  # パフォーマンス監視設定
  def performance_config
    @performance_config ||= {
      enable_timing: ENV.fetch('DEBUG_TIMING', 'false') == 'true',
      enable_memory_monitoring: ENV.fetch('DEBUG_MEMORY', 'false') == 'true',
      enable_benchmark: ENV.fetch('PERFORMANCE_BENCHMARK', 'false') == 'true',
      slow_test_threshold: ENV.fetch('SLOW_TEST_THRESHOLD', 1000).to_i # ms
    }
  end
  
  # テストデータ設定
  def test_data_config
    @test_data_config ||= {
      admin_password: ENV.fetch('TEST_ADMIN_PASSWORD', "test_secure_password_#{Rails.env}"),
      admin_email: ENV.fetch('TEST_ADMIN_EMAIL', 'admin@example.com'),
      admin_user_id: ENV.fetch('TEST_ADMIN_USER_ID', 'admin123'),
      use_factories: ENV.fetch('USE_TEST_FACTORIES', 'true') == 'true'
    }
  end
  
  # CI環境設定
  def ci_config
    @ci_config ||= {
      is_ci: ENV['CI'] || ENV['GITHUB_ACTIONS'],
      skip_system_tests: ENV.fetch('SKIP_SYSTEM_TESTS', 'false') == 'true',
      skip_playwright_tests: ENV.fetch('SKIP_PLAYWRIGHT_TESTS', 'false') == 'true'
    }
  end
  
  # 環境別設定の取得
  def for_environment(env = Rails.env)
    case env.to_s
    when 'test'
      test_environment_config
    when 'development'
      development_environment_config
    else
      default_environment_config
    end
  end
  
  # 設定のバリデーション
  def validate_configuration!
    errors = []
    
    # 必須設定の確認
    if test_data_config[:admin_password].length < 8
      errors << "TEST_ADMIN_PASSWORD must be at least 8 characters"
    end
    
    if playwright_config[:timeout] < 1000
      errors << "PLAYWRIGHT_TIMEOUT must be at least 1000ms"
    end
    
    if database_config[:connection_pool_size] < 1
      errors << "TEST_DB_POOL_SIZE must be at least 1"
    end
    
    unless %w[truncation deletion].include?(database_config[:cleanup_strategy])
      errors << "TEST_CLEANUP_STRATEGY must be 'truncation' or 'deletion'"
    end
    
    raise ConfigurationError, errors.join('; ') if errors.any?
    
    true
  end
  
  # 設定の表示（デバッグ用）
  def dump_configuration
    return unless ENV['DEBUG_CONFIGURATION'] == 'true'
    
    puts "\n=== Test Configuration ==="
    puts "Database: #{database_config}"
    puts "Playwright: #{playwright_config}"
    puts "Performance: #{performance_config}"
    puts "Test Data: #{test_data_config.except(:admin_password)}" # パスワードは除外
    puts "CI: #{ci_config}"
    puts "=========================="
  end
  
  private
  
  def test_environment_config
    {
      cache_store: :memory_store,
      log_level: :warn,
      eager_load: false
    }
  end
  
  def development_environment_config
    {
      cache_store: :file_store,
      log_level: :debug,
      eager_load: false
    }
  end
  
  def default_environment_config
    {
      cache_store: :null_store,
      log_level: :info,
      eager_load: true
    }
  end
  
  class ConfigurationError < StandardError; end
end