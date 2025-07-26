class FormErrorsComponent < ViewComponent::Base
  def initialize(object:)
    @object = object
  end

  def render?
    object.errors.any?
  end

  private

  attr_reader :object

  def alert_component
    AlertComponent.new(
      type: :danger,
      messages: object.errors.full_messages,
      spec_class: "spec--error-messages"
    )
  end
end
