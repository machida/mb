class PageTitleComponent < ViewComponent::Base
  def initialize(title:, title_class: nil, action_button: nil)
    @title = title
    @title_class = title_class
    @action_button = action_button
  end

  private

  attr_reader :title, :title_class, :action_button
end