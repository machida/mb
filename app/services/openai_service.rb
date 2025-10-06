# OpenAI API連携サービス
#
# @example 記事の概要を生成する
#   service = OpenaiService.new
#   result = service.generate_summary(title: "タイトル", body: "本文")
#   if result[:success]
#     puts result[:summary]
#   else
#     puts result[:error]
#   end
class OpenaiService
  API_ENDPOINT = "https://api.openai.com/v1/chat/completions"
  MODEL = "gpt-4o-mini"
  MAX_TOKENS = 200

  # 記事の概要を生成する
  #
  # @param title [String] 記事のタイトル
  # @param body [String] 記事の本文（Markdown）
  # @return [Hash] 成功時: { success: true, summary: String }、失敗時: { success: false, error: String }
  def generate_summary(title:, body:)
    api_key = SiteSetting.openai_api_key

    if api_key.blank?
      return { success: false, error: "OpenAI API Keyが設定されていません" }
    end

    if title.blank? || body.blank?
      return { success: false, error: "タイトルと本文を入力してください" }
    end

    begin
      response = call_openai_api(api_key, title, body)
      { success: true, summary: response }
    rescue StandardError => e
      Rails.logger.error "OpenAI API error: #{e.message}"
      error_detail = Rails.env.production? ? "" : ": #{e.message}"
      { success: false, error: "概要の生成に失敗しました#{error_detail}" }
    end
  end

  private

  # OpenAI APIを呼び出す
  #
  # @param api_key [String] OpenAI API Key
  # @param title [String] 記事のタイトル
  # @param body [String] 記事の本文
  # @return [String] 生成された概要
  # @raise [StandardError] API呼び出しエラー
  def call_openai_api(api_key, title, body)
    uri = URI.parse(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{api_key}"

    request.body = {
      model: MODEL,
      messages: [
        {
          role: "system",
          content: "あなたは記事の概要を作成する専門家です。与えられた記事のタイトルと本文から、meta descriptionとして使用できる簡潔で分かりやすい概要を100文字程度で作成してください。"
        },
        {
          role: "user",
          content: "以下の記事の概要を100文字程度で作成してください。\n\nタイトル: #{title}\n\n本文:\n#{body}"
        }
      ],
      max_tokens: MAX_TOKENS,
      temperature: 0.3
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      error_message = parse_error_message(response)
      raise StandardError, error_message
    end

    result = JSON.parse(response.body)
    result.dig("choices", 0, "message", "content")&.strip || raise(StandardError, "Invalid response format")
  end

  # エラーメッセージをパースする
  #
  # @param response [Net::HTTPResponse] HTTPレスポンス
  # @return [String] エラーメッセージ
  def parse_error_message(response)
    error_body = JSON.parse(response.body) rescue {}
    error_message = error_body.dig("error", "message") || "Unknown error"
    "API request failed (#{response.code}): #{error_message}"
  end
end
