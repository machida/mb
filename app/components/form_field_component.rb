class FormFieldComponent < ViewComponent::Base
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

  def css_class
    "a--text-input #{spec_class}".strip
  end

  def textarea?
    type == "textarea"
  end

  def email?
    type == "email"
  end

  def password?
    type == "password"
  end
end
