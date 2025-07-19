class PageTitleComponent < ViewComponent::Base
  def initialize(title:, title_class: nil)
    @title = title
    @title_class = title_class
  end

  private

  attr_reader :title, :title_class
end