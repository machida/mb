require "test_helper"

class AlertComponentTest < ViewComponent::TestCase
  test "should render with danger type and message" do
    result = render_inline(AlertComponent.new(type: :danger, message: "エラーメッセージ"))
    html = result.to_html

    assert_includes html, "a--card"
    assert_includes html, "is--danger"
    assert_includes html, "text-red-700"
    assert_includes html, "エラーメッセージ"
    assert_includes html, "エラーが発生しました" # default title for danger
  end

  test "should render with warning type" do
    result = render_inline(AlertComponent.new(type: :warning, message: "警告メッセージ"))
    html = result.to_html

    assert_includes html, "a--card"
    assert_includes html, "is--warning"
    assert_includes html, "text-orange-700"
    assert_includes html, "警告メッセージ"
    assert_includes html, "警告" # default title for warning
  end

  test "should render with info type" do
    result = render_inline(AlertComponent.new(type: :info, message: "お知らせメッセージ"))
    html = result.to_html

    assert_includes html, "a--card"
    assert_includes html, "is--info"
    assert_includes html, "text-cyan-700"
    assert_includes html, "お知らせメッセージ"
    assert_includes html, "お知らせ" # default title for info
  end

  test "should render with primary type" do
    result = render_inline(AlertComponent.new(type: :primary, message: "プライマリメッセージ"))
    html = result.to_html

    assert_includes html, "a--card"
    assert_includes html, "is--primary"
    assert_includes html, "text-blue-700"
    assert_includes html, "プライマリメッセージ"
  end

  test "should render with secondary type" do
    result = render_inline(AlertComponent.new(type: :secondary, message: "セカンダリメッセージ"))
    html = result.to_html

    assert_includes html, "a--card"
    assert_includes html, "is--secondary"
    assert_includes html, "text-gray-700"
    assert_includes html, "セカンダリメッセージ"
  end

  test "should use default danger color for unknown type" do
    result = render_inline(AlertComponent.new(type: :unknown, message: "メッセージ"))
    html = result.to_html

    assert_includes html, "a--card"
    assert_includes html, "is--unknown"
    assert_includes html, "text-red-700"
  end

  test "should render with custom title" do
    result = render_inline(AlertComponent.new(
      type: :danger,
      message: "エラーメッセージ",
      title: "カスタムタイトル"
    ))
    html = result.to_html

    assert_includes html, "カスタムタイトル"
    assert_not_includes html, "エラーが発生しました"
  end

  test "should render with multiple messages" do
    messages = ["エラー1", "エラー2", "エラー3"]
    result = render_inline(AlertComponent.new(type: :danger, messages: messages))
    html = result.to_html

    messages.each do |message|
      assert_includes html, message
    end
  end

  test "should render with spec_class" do
    result = render_inline(AlertComponent.new(
      type: :danger,
      message: "エラーメッセージ",
      spec_class: "spec--custom-alert"
    ))
    html = result.to_html

    assert_includes html, "spec--custom-alert"
  end

  test "should not render when no message or messages" do
    component = AlertComponent.new(type: :danger)

    assert_not component.render?
  end

  test "should not render when messages is empty array" do
    component = AlertComponent.new(type: :danger, messages: [])

    assert_not component.render?
  end

  test "should render when message is present" do
    component = AlertComponent.new(type: :danger, message: "エラー")

    assert component.render?
  end

  test "should render when messages is non-empty array" do
    component = AlertComponent.new(type: :danger, messages: ["エラー1"])

    assert component.render?
  end

  test "should not render title for primary type when no custom title" do
    result = render_inline(AlertComponent.new(type: :primary, message: "メッセージ"))
    html = result.to_html

    # Primary type has no default title
    assert_not_includes html, "エラーが発生しました"
    assert_not_includes html, "警告"
    assert_not_includes html, "お知らせ"
  end

  test "should not render title for secondary type when no custom title" do
    result = render_inline(AlertComponent.new(type: :secondary, message: "メッセージ"))
    html = result.to_html

    # Secondary type has no default title
    assert_not_includes html, "エラーが発生しました"
    assert_not_includes html, "警告"
    assert_not_includes html, "お知らせ"
  end
end
