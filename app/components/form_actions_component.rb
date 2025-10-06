# フォームアクションボタンを表示するコンポーネント
#
# プライマリボタン、セカンダリボタン、キャンセルリンクを統一的に表示します。
# spec_classでテスト用クラスをカスタマイズ可能です。
class FormActionsComponent < ViewComponent::Base
  # フォームアクションコンポーネントを初期化
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダーオブジェクト
  # @param primary_label [String] プライマリボタンのラベル
  # @param primary_class [String] プライマリボタンのテスト用CSSクラス
  # @param secondary_label [String, nil] セカンダリボタンのラベル（nilの場合は非表示）
  # @param secondary_class [String] セカンダリボタンのテスト用CSSクラス
  # @param cancel_path [String, nil] キャンセルリンクのパス（nilの場合は非表示）
  # @param cancel_label [String] キャンセルリンクのラベル
  # @raise [ArgumentError] formがnilの場合
  def initialize(
    form:,
    primary_label: "保存",
    primary_class: "spec--save-button",
    secondary_label: nil,
    secondary_class: "spec--draft-button",
    cancel_path: nil,
    cancel_label: "キャンセル"
  )
    raise ArgumentError, "form is required" if form.nil?

    @form = form
    @primary_label = primary_label
    @primary_class = primary_class
    @secondary_label = secondary_label
    @secondary_class = secondary_class
    @cancel_path = cancel_path
    @cancel_label = cancel_label
  end

  private

  attr_reader :form
  attr_reader :primary_label, :primary_class
  attr_reader :secondary_label, :secondary_class
  attr_reader :cancel_path, :cancel_label

  # セカンダリボタンを表示するかどうかを判定
  #
  # @return [Boolean] セカンダリボタンを表示する場合true
  def show_secondary?
    secondary_label.present?
  end

  # キャンセルリンクを表示するかどうかを判定
  #
  # @return [Boolean] キャンセルリンクを表示する場合true
  def show_cancel?
    cancel_path.present?
  end
end
