require "test_helper"

class OpenaiServiceTest < ActiveSupport::TestCase
  def setup
    @service = OpenaiService.new
    @valid_title = "テスト記事のタイトル"
    @valid_body = "これはテスト記事の本文です。" * 10
  end

  def teardown
    # テスト後にキャッシュをクリア
    Rails.cache.delete("site_setting_openai_api_key")
  end

  test "API keyが未設定の場合はエラーを返す" do
    SiteSetting.set("openai_api_key", "")

    result = @service.generate_summary(title: @valid_title, body: @valid_body)

    assert_not result[:success]
    assert_equal "OpenAI API Keyが設定されていません", result[:error]
  end

  test "タイトルが空の場合はエラーを返す" do
    SiteSetting.set("openai_api_key", "test-key")

    result = @service.generate_summary(title: "", body: @valid_body)

    assert_not result[:success]
    assert_equal "タイトルと本文を入力してください", result[:error]
  end

  test "本文が空の場合はエラーを返す" do
    SiteSetting.set("openai_api_key", "test-key")

    result = @service.generate_summary(title: @valid_title, body: "")

    assert_not result[:success]
    assert_equal "タイトルと本文を入力してください", result[:error]
  end

  test "OpenAI APIが正常なレスポンスを返す場合は成功する" do
    SiteSetting.set("openai_api_key", "test-key")

    # モックレスポンス
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => "これはAIが生成したテスト概要です。"
          }
        }
      ]
    }

    # Net::HTTPをスタブ化
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 200, body: mock_response.to_json, headers: { "Content-Type" => "application/json" })

    result = @service.generate_summary(title: @valid_title, body: @valid_body)

    assert result[:success]
    assert_equal "これはAIが生成したテスト概要です。", result[:summary]
  end

  test "OpenAI APIがエラーを返す場合は失敗する" do
    SiteSetting.set("openai_api_key", "invalid-key")

    # エラーレスポンス
    error_response = {
      "error" => {
        "message" => "Invalid API key"
      }
    }

    # Net::HTTPをスタブ化
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(status: 401, body: error_response.to_json, headers: { "Content-Type" => "application/json" })

    result = @service.generate_summary(title: @valid_title, body: @valid_body)

    assert_not result[:success]
    assert_match(/Invalid API key/, result[:error])
  end

  test "ネットワークエラーが発生した場合は失敗する" do
    SiteSetting.set("openai_api_key", "test-key")

    # Net::HTTPをスタブ化してエラーを発生させる
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_raise(StandardError.new("Network error"))

    result = @service.generate_summary(title: @valid_title, body: @valid_body)

    assert_not result[:success]
    assert_match(/Network error/, result[:error])
  end
end
