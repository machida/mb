class FormActionsComponent < ViewComponent::Base
  def initialize(form:, primary_label: "保存", primary_class: "spec--save-button", secondary_label: nil, secondary_class: "spec--draft-button", cancel_path: nil, cancel_label: "キャンセル")
    @form = form
    @primary_label = primary_label
    @primary_class = primary_class
    @secondary_label = secondary_label
    @secondary_class = secondary_class
    @cancel_path = cancel_path
    @cancel_label = cancel_label
  end

  private

  attr_reader :form, :primary_label, :primary_class, :secondary_label, :secondary_class, :cancel_path, :cancel_label

  def show_secondary?
    secondary_label.present?
  end

  def show_cancel?
    cancel_path.present?
  end
end
