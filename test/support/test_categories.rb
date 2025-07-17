# test/support/test_categories.rb
# テストカテゴリの分離と管理
module TestCategories
  extend ActiveSupport::Concern
  
  # テストカテゴリのマーカーモジュール
  module UnitTest; end
  module IntegrationTest; end
  module SystemTest; end
  module PerformanceTest; end
  module SecurityTest; end
  
  included do
    # テストカテゴリのタグ機能
    class_attribute :test_category, default: :unit
    class_attribute :test_tags, default: []
  end
  
  class_methods do
    # カテゴリ設定
    def category(cat)
      self.test_category = cat
    end
    
    # タグ設定
    def tags(*tag_list)
      self.test_tags = tag_list.flatten
    end
    
    # 特定カテゴリのテストかチェック
    def unit_test?
      test_category == :unit
    end
    
    def integration_test?
      test_category == :integration
    end
    
    def system_test?
      test_category == :system
    end
    
    def performance_test?
      test_category == :performance
    end
    
    def security_test?
      test_category == :security
    end
    
    # 特定タグを持つかチェック
    def has_tag?(tag)
      test_tags.include?(tag.to_sym)
    end
  end
  
  # インスタンスメソッド
  def test_category
    self.class.test_category
  end
  
  def test_tags
    self.class.test_tags
  end
  
  def unit_test?
    self.class.unit_test?
  end
  
  def integration_test?
    self.class.integration_test?
  end
  
  def system_test?
    self.class.system_test?
  end
  
  def performance_test?
    self.class.performance_test?
  end
  
  def security_test?
    self.class.security_test?
  end
  
  def has_tag?(tag)
    self.class.has_tag?(tag)
  end
  
  # カテゴリ別の実行フィルタ
  module Filters
    extend self
    
    # 環境変数によるフィルタリング
    def should_run_test?(test_class)
      return true unless filter_enabled?
      
      category_filter = ENV['TEST_CATEGORY']
      tag_filter = ENV['TEST_TAGS']
      
      if category_filter
        return false unless test_class.test_category.to_s == category_filter
      end
      
      if tag_filter
        required_tags = tag_filter.split(',').map(&:strip).map(&:to_sym)
        return false unless (required_tags & test_class.test_tags).any?
      end
      
      true
    end
    
    # CI環境での特別フィルタ
    def should_skip_in_ci?(test_class)
      ci_config = TestConfiguration.ci_config
      
      # CI環境でシステムテストをスキップ
      if ci_config[:skip_system_tests] && test_class.system_test?
        return true
      end
      
      # CI環境でPlaywrightテストをスキップ
      if ci_config[:skip_playwright_tests] && test_class.has_tag?(:playwright)
        return true
      end
      
      false
    end
    
    private
    
    def filter_enabled?
      ENV['TEST_CATEGORY'] || ENV['TEST_TAGS']
    end
  end
  
  # セットアップフック
  def setup
    super
    
    # CI環境でのスキップ判定
    if TestCategories::Filters.should_skip_in_ci?(self.class)
      skip "Test category #{test_category} skipped in CI environment"
    end
    
    # フィルタによるスキップ判定
    unless TestCategories::Filters.should_run_test?(self.class)
      skip "Test filtered out by TEST_CATEGORY or TEST_TAGS"
    end
  end
end

# 具体的なテストカテゴリクラス
module TestCategories
  class UnitTestCase < ApplicationTestCase
    include TestCategories
    category :unit
    
    # 高速実行のための最適化
    def setup
      super
      # 軽量なセットアップのみ
      fast_cleanup if respond_to?(:fast_cleanup)
    end
  end
  
  class SecurityTestCase < ApplicationTestCase
    include TestCategories
    category :security
    tags :security, :auth
    
    def setup
      super
      # セキュリティテスト用の特別なセットアップ
      setup_security_test_environment
    end
    
    private
    
    def setup_security_test_environment
      # セキュリティテスト用の設定
      Rails.logger.level = :warn # ログレベルを上げる
    end
  end
  
  class PerformanceTestCase < ApplicationTestCase
    include TestCategories
    category :performance
    tags :performance, :slow
    
    def setup
      super
      # パフォーマンステスト用のセットアップ
      setup_performance_monitoring
    end
    
    private
    
    def setup_performance_monitoring
      if ENV['PERFORMANCE_BENCHMARK'] == 'true'
        @benchmark = PerformanceHelpers::PerformanceBenchmark.new(self.class.name)
      end
    end
  end
end