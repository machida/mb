ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

# TestConfigurationを先に読み込み
require_relative "support/test_configuration"

module TestConfig
  # Centralized test configuration using TestConfiguration
  def self.included(base)
    config = TestConfiguration.test_data_config
    base.const_set(:TEST_ADMIN_PASSWORD, config[:admin_password])
    base.const_set(:TEST_ADMIN_EMAIL, config[:admin_email])
    base.const_set(:TEST_ADMIN_USER_ID, config[:admin_user_id])
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # 基本的な設定のみ（具体的な機能は階層化されたクラスで提供）
    include TestConfig
  end
end

# まず基本的なヘルパーモジュールを読み込み
require_relative "support/selectors"
require_relative "support/test_data_factory"
require_relative "support/authentication_helpers"
require_relative "support/assertion_helpers"
require_relative "support/playwright_helpers"
require_relative "support/performance_helpers"
require_relative "support/security_helpers"
require_relative "support/base_test_case"

# 階層化されたベースクラスを設定
class ApplicationTestCase < ActiveSupport::TestCase
  include BaseTestCaseExtensions
  include TestDataFactory
  include AssertionHelpers
  include PerformanceHelpers::TimingHelpers
  include PerformanceHelpers::EfficientTestData
end

require_relative "support/test_categories"

# 設定の検証とダンプ
TestConfiguration.validate_configuration!
TestConfiguration.dump_configuration

# 階層化されたクラスを読み込み
require_relative "support/integration_test_case"
require_relative "support/system_test_case"

# 残りのサポートファイルを読み込み
Dir[Rails.root.join("test/support/**/*.rb")].each do |f|
  filename = File.basename(f, ".rb")
  # 既に読み込み済みのファイルはスキップ
  unless %w[test_configuration selectors test_data_factory authentication_helpers assertion_helpers playwright_helpers performance_helpers test_categories security_helpers base_test_case integration_test_case system_test_case].include?(filename)
    require f
  end
end
