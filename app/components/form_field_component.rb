# フォームフィールドを表示するコンポーネント
#
# テキスト、メール、パスワード、テキストエリアなどの入力フィールドを統一的に表示します。
# ラベル、ヘルプテキスト、バリデーション、autocomplete属性をサポートします。
class FormFieldComponent < ViewComponent::Base
  # フォームフィールドコンポーネントを初期化
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダーオブジェクト
  # @param field [Symbol] フィールド名
  # @param label [String] ラベルテキスト
  # @param type [String] 入力タイプ ("text", "email", "password", "textarea")
  # @param required [Boolean] 必須フィールドかどうか
  # @param placeholder [String] プレースホルダーテキスト
  # @param help_text [String] ヘルプテキスト
  # @param spec_class [String] テスト用CSSクラス
  # @param rows [Integer] テキストエリアの行数
  # @param autocomplete [String, nil] autocomplete属性の値
  def initialize(
    form:,
    field:,
    label:,
    type: "text",
    required: false,
    placeholder: "",
    help_text: "",
    spec_class: "",
    rows: 3,
    autocomplete: nil
  )
    @form = form
    @field = field
    @label = label
    @type = type
    @required = required
    @placeholder = placeholder
    @help_text = help_text
    @spec_class = spec_class
    @rows = rows
    @autocomplete = autocomplete
  end

  private

  attr_reader :form, :field, :label, :type, :required, :placeholder, :help_text, :spec_class, :rows, :autocomplete

  # 入力フィールドのCSSクラスを生成
  #
  # @return [String] CSSクラス文字列
  def css_class
    "a--text-input #{spec_class}".strip
  end

  # テキストエリアかどうかを判定
  #
  # @return [Boolean] テキストエリアの場合true
  def textarea?
    type == "textarea"
  end

  # メールフィールドかどうかを判定
  #
  # @return [Boolean] メールフィールドの場合true
  def email?
    type == "email"
  end

  # パスワードフィールドかどうかを判定
  #
  # @return [Boolean] パスワードフィールドの場合true
  def password?
    type == "password"
  end
end
