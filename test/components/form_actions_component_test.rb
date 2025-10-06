require "test_helper"

class FormActionsComponentTest < ViewComponent::TestCase
  def test_initialization_with_valid_form
    component = FormActionsComponent.new(form: mock_form_builder)
    assert_not_nil component
  end

  def test_nil_form_raises_argument_error
    error = assert_raises(ArgumentError) do
      FormActionsComponent.new(form: nil)
    end

    assert_equal "form is required", error.message
  end

  def test_initialization_with_all_parameters
    component = FormActionsComponent.new(
      form: mock_form_builder,
      primary_label: "送信",
      primary_class: "spec--submit",
      secondary_label: "下書き保存",
      secondary_class: "spec--draft",
      cancel_path: "/admin/articles",
      cancel_label: "戻る"
    )
    assert_not_nil component
  end

  private

  def mock_form_builder
    @mock_form_builder ||= begin
      builder = Object.new
      builder.define_singleton_method(:submit) { |*args| "" }
      builder
    end
  end
end
