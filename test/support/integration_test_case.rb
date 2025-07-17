# test/support/integration_test_case.rb
# 統合テスト（コントローラーテスト）用の基底クラス
class IntegrationTestCase < ActionDispatch::IntegrationTest
  include BaseTestCaseExtensions
  include TestDataFactory
  include AssertionHelpers
  include PerformanceHelpers::TimingHelpers
  include PerformanceHelpers::EfficientTestData
  include AuthenticationHelpers
  include TestConfig
  include TestCategories
  
  category :integration
  tags :controller, :integration
  
  def setup
    super
    # 統合テスト用の高速データクリーンアップ
    with_performance_measurement("Data cleanup") do
      fast_cleanup
    end
    # デフォルトのサイト設定を作成
    create_default_site_settings
  end
  
  def teardown
    super
    # セッション情報のクリア
    reset_session if respond_to?(:reset_session)
  end
  
  protected
  
  # デフォルトのサイト設定を作成
  def create_default_site_settings
    return if SiteSetting.exists?
    
    SiteSetting.create!([
      { name: "site_title", value: "テストサイト" },
      { name: "copyright", value: "Test Copyright" },
      { name: "top_page_description", value: "テスト用の説明" },
      { name: "default_og_image", value: "https://example.com/test-og-image.jpg" }
    ])
  end
  
  # レスポンスボディの内容確認用ヘルパー
  def assert_response_contains(text, message = nil)
    assert_includes response.body, text, message || "Expected response to contain: #{text}"
  end
  
  def assert_response_not_contains(text, message = nil)
    assert_not_includes response.body, text, message || "Expected response not to contain: #{text}"
  end
  
  # フラッシュメッセージの確認
  def assert_flash_message(type, message)
    assert_equal message, flash[type], "Expected flash[#{type}] to be '#{message}'"
  end
  
  # JSON APIテスト用のヘルパー
  def post_json(path, params = {})
    post path, params: params.to_json, headers: { 'Content-Type' => 'application/json' }
  end
  
  def put_json(path, params = {})
    put path, params: params.to_json, headers: { 'Content-Type' => 'application/json' }
  end
  
  def patch_json(path, params = {})
    patch path, params: params.to_json, headers: { 'Content-Type' => 'application/json' }
  end
end