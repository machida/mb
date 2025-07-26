class AlertComponent < ViewComponent::Base
  def initialize(type: :danger, message: nil, messages: nil, title: nil, spec_class: nil)
    @type = type
    @message = message
    @messages = messages
    @title = title
    @spec_class = spec_class
  end

  def render?
    message.present? || (messages.present? && messages.any?)
  end

  private

  attr_reader :type, :message, :messages, :title, :spec_class

  def card_classes
    classes = [ "a--card", "is-#{type}", color_class ]
    classes << spec_class if spec_class.present?
    classes.compact.join(" ")
  end

  def color_class
    case type
    when :danger
      "text-red-700"
    when :warning
      "text-orange-700"
    when :info
      "text-cyan-700"
    when :primary
      "text-blue-700"
    when :secondary
      "text-gray-700"
    else
      "text-red-700"
    end
  end

  def default_title
    case type
    when :danger
      "エラーが発生しました"
    when :warning
      "警告"
    when :info
      "お知らせ"
    else
      nil
    end
  end

  def display_title
    title || default_title
  end
end
