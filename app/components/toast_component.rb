# トースト通知を表示するコンポーネント
#
# 成功メッセージやエラーメッセージをトースト形式で表示します。
# アイコンと背景色は自動的に切り替わります。
class ToastComponent < ViewComponent::Base
  # トースト通知コンポーネントを初期化
  #
  # @param message [String] 表示するメッセージ
  # @param type [Symbol] 通知タイプ (:success または :error)
  def initialize(message:, type: :success)
    @message = message
    @type = type
  end

  # コンポーネントを表示するかどうかを判定
  #
  # @return [Boolean] メッセージが存在する場合true
  def render?
    message.present?
  end

  private

  attr_reader :message, :type

  # 背景色のCSSクラスを取得
  #
  # @return [String] 背景色のCSSクラス
  def background_color
    type == :success ? "bg-green-500" : "bg-red-500"
  end

  # アイコンのSVGパスを取得
  #
  # @return [String] SVGパス文字列
  def icon_path
    if type == :success
      "M5 13l4 4L19 7"
    else
      "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 15.5c-.77.833.192 2.5 1.732 2.5z"
    end
  end
end
