# test/support/performance_helpers.rb
module PerformanceHelpers
  extend self
  
  # 高速なデータベースクリーンアップ
  module DatabaseCleaner
    extend self
    
    def clean_with_truncation
      # MySQLの場合の最適化
      if mysql_adapter?
        execute_sql("SET FOREIGN_KEY_CHECKS = 0")
        truncate_tables
        execute_sql("SET FOREIGN_KEY_CHECKS = 1")
      else
        # PostgreSQLや他のDBの場合
        truncate_tables
      end
      
      # シーケンスリセット
      TestDataFactory::SequenceGenerator.reset
    end
    
    def clean_with_deletion
      # 関連順序を考慮した削除
      %w[Article Admin SiteSetting].each do |model_name|
        model_name.constantize.delete_all
      end
      
      TestDataFactory::SequenceGenerator.reset
    end
    
    private
    
    def truncate_tables
      %w[articles admins site_settings].each do |table|
        execute_sql("TRUNCATE TABLE #{table}")
      end
    end
    
    def execute_sql(sql)
      ActiveRecord::Base.connection.execute(sql)
    end
    
    def mysql_adapter?
      ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
    end
  end
  
  # テスト実行時間の測定
  module TimingHelpers
    def measure_time(description = "Operation")
      start_time = Time.current
      result = yield
      end_time = Time.current
      duration = ((end_time - start_time) * 1000).round(2)
      
      if ENV['DEBUG_TIMING'] == 'true'
        puts "#{description}: #{duration}ms"
      end
      
      result
    end
    
    def assert_performance(max_duration_ms, description = "Performance test")
      duration = measure_time(description) { yield }
      assert duration <= max_duration_ms, 
             "#{description} took #{duration}ms, expected <= #{max_duration_ms}ms"
    end
  end
  
  # リソース使用量の監視
  module ResourceMonitor
    def monitor_memory_usage
      before_memory = memory_usage
      result = yield
      after_memory = memory_usage
      memory_diff = after_memory - before_memory
      
      if ENV['DEBUG_MEMORY'] == 'true'
        puts "Memory usage: #{memory_diff}MB (before: #{before_memory}MB, after: #{after_memory}MB)"
      end
      
      result
    end
    
    private
    
    def memory_usage
      `ps -o rss= -p #{Process.pid}`.to_i / 1024.0 # MB
    rescue
      0
    end
  end
  
  # テストデータの効率的な管理
  module EfficientTestData
    def with_minimal_data(&block)
      # 必要最小限のデータのみでテスト実行
      clear_unnecessary_data
      yield
    end
    
    def with_cached_data(cache_key, &block)
      @data_cache ||= {}
      
      unless @data_cache[cache_key]
        @data_cache[cache_key] = yield
      end
      
      @data_cache[cache_key]
    end
    
    def clear_data_cache
      @data_cache&.clear
    end
    
    private
    
    def clear_unnecessary_data
      # 古いテストデータや不要なレコードを削除
      # 本プロジェクトでは特に重要なロジックはないため、基本的なクリーンアップ
      Rails.cache.clear
    end
  end
  
  # 並列実行の最適化
  module ParallelOptimization
    def self.configure_for_test_env
      # テスト環境での並列実行設定
      configure_database_connections
      configure_cache_settings
    end
    
    private
    
    def self.configure_database_connections
      # データベースコネクションプールの最適化
      ActiveRecord::Base.connection_pool.disconnect!
      
      config = ActiveRecord::Base.configurations[Rails.env]
      config['pool'] = [ENV.fetch('TEST_DB_POOL_SIZE', 10).to_i, 5].max
      
      ActiveRecord::Base.establish_connection(config)
    end
    
    def self.configure_cache_settings
      # テスト用のキャッシュ設定
      Rails.application.config.cache_store = :memory_store, { size: 64.megabytes }
    end
  end
  
  # ファイルシステム操作の最適化
  module FileSystemOptimization
    def with_tmp_dir(prefix = "test_")
      Dir.mktmpdir(prefix) do |tmp_dir|
        yield tmp_dir
      end
    end
    
    def cleanup_tmp_files(pattern = "test_*")
      Dir.glob(File.join(Rails.root, "tmp", pattern)).each do |file|
        File.delete(file) if File.file?(file)
      end
    end
  end
  
  # パフォーマンステストのベンチマーク
  class PerformanceBenchmark
    def initialize(name)
      @name = name
      @measurements = []
    end
    
    def measure(&block)
      start_time = Time.current
      result = yield
      duration = Time.current - start_time
      @measurements << duration
      result
    end
    
    def report
      return if @measurements.empty?
      
      avg = @measurements.sum / @measurements.size
      min = @measurements.min
      max = @measurements.max
      
      puts "=== Performance Report: #{@name} ==="
      puts "Measurements: #{@measurements.size}"
      puts "Average: #{(avg * 1000).round(2)}ms"
      puts "Min: #{(min * 1000).round(2)}ms"
      puts "Max: #{(max * 1000).round(2)}ms"
      puts "================================="
    end
  end
  
  # テストスイート全体のパフォーマンス監視
  module SuitePerformanceMonitor
    extend self
    
    @start_time = nil
    @test_count = 0
    
    def start_suite
      @start_time = Time.current
      @test_count = 0
    end
    
    def record_test
      @test_count += 1
    end
    
    def finish_suite
      return unless @start_time
      
      total_duration = Time.current - @start_time
      avg_per_test = @test_count > 0 ? total_duration / @test_count : 0
      
      puts "\n=== Test Suite Performance ==="
      puts "Total time: #{total_duration.round(2)}s"
      puts "Tests run: #{@test_count}"
      puts "Average per test: #{(avg_per_test * 1000).round(2)}ms"
      puts "=============================="
    end
  end
end