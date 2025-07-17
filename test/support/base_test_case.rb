# test/support/base_test_case.rb
# ApplicationTestCaseの拡張メソッド（モジュールとして定義）
module BaseTestCaseExtensions
  extend ActiveSupport::Concern
  
  included do
    # パフォーマンス監視用
    cattr_accessor :performance_benchmark
  end
  
  # 全テスト共通のセットアップ
  def setup
    super
    # パフォーマンス測定開始
    PerformanceHelpers::SuitePerformanceMonitor.record_test
    
    # キャッシュクリア（軽量な操作）
    Rails.cache.clear
    
    # パフォーマンステスト用ベンチマーク
    if ENV['PERFORMANCE_BENCHMARK'] == 'true'
      self.class.performance_benchmark ||= PerformanceHelpers::PerformanceBenchmark.new(self.class.name)
    end
  end
  
  # 全テスト共通のティアダウン  
  def teardown
    super
    # 必要最小限のクリーンアップのみ
    clear_data_cache if respond_to?(:clear_data_cache)
  end
  
  protected
  
  # テスト環境の検証
  def assert_test_environment
    assert_equal "test", Rails.env
  end
  
  # 高速なデータクリーンアップ（必要に応じて使用）
  def fast_cleanup
    PerformanceHelpers::DatabaseCleaner.clean_with_truncation
  end
  
  # 標準的なデータクリーンアップ
  def standard_cleanup
    PerformanceHelpers::DatabaseCleaner.clean_with_deletion
  end
  
  # パフォーマンス測定付きのブロック実行
  def with_performance_measurement(description = "Test operation", &block)
    if ENV['DEBUG_TIMING'] == 'true'
      measure_time(description, &block)
    else
      yield
    end
  end
  
  # デバッグ用のヘルパー
  def debug_test_state
    return unless ENV['DEBUG_TESTS'] == 'true'
    puts "=== Test State Debug ==="
    puts "Admin count: #{Admin.count}"
    puts "Article count: #{Article.count}"
    puts "Memory usage: #{memory_usage}MB" if respond_to?(:memory_usage, true)
    puts "======================="
  end
  
  private
  
  def memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue
    0
  end
end