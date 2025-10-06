require "test_helper"

class FormFieldComponentTest < ViewComponent::TestCase
  def test_valid_types
    FormFieldComponent::VALID_TYPES.each do |type|
      component = FormFieldComponent.new(
        form: mock_form_builder,
        field: :test_field,
        label: "Test Label",
        type: type
      )
      assert_not_nil component
    end
  end

  def test_invalid_type_raises_argument_error
    error = assert_raises(ArgumentError) do
      FormFieldComponent.new(
        form: mock_form_builder,
        field: :test_field,
        label: "Test Label",
        type: "invalid_type"
      )
    end

    assert_match(/Invalid type: invalid_type/, error.message)
    assert_match(/Allowed types: text, email, password, textarea/, error.message)
  end

  def test_nil_form_raises_argument_error
    error = assert_raises(ArgumentError) do
      FormFieldComponent.new(
        form: nil,
        field: :test_field,
        label: "Test Label"
      )
    end

    assert_equal "form is required", error.message
  end

  private

  def mock_form_builder
    @mock_form_builder ||= begin
      builder = Object.new
      builder.define_singleton_method(:label) { |*args| "" }
      builder.define_singleton_method(:text_field) { |*args| "" }
      builder.define_singleton_method(:email_field) { |*args| "" }
      builder.define_singleton_method(:password_field) { |*args| "" }
      builder.define_singleton_method(:text_area) { |*args| "" }
      builder
    end
  end
end
