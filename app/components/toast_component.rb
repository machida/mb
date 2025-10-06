class ToastComponent < ViewComponent::Base
  def initialize(message:, type: :success)
    @message = message
    @type = type
  end

  def render?
    message.present?
  end

  private

  attr_reader :message, :type

  def background_color
    type == :success ? "bg-green-500" : "bg-red-500"
  end

  def icon_path
    if type == :success
      "M5 13l4 4L19 7"
    else
      "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 15.5c-.77.833.192 2.5 1.732 2.5z"
    end
  end
end
