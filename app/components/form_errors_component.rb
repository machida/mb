class FormErrorsComponent < ViewComponent::Base
  def initialize(object:)
    @object = object
  end

  def render?
    object.errors.any?
  end

  private

  attr_reader :object
end