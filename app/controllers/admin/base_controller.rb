class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :require_admin

  protected

  def set_success_message(message)
    flash[:notice] = message
  end

  def set_error_message(message)
    flash[:alert] = message
  end

  def handle_validation_errors(object)
    if object.errors.any?
      set_error_message(object.errors.full_messages.join(", "))
      return false
    end
    true
  end

  def render_with_errors(template, object, status = :unprocessable_entity)
    handle_validation_errors(object)
    render template, status: status
  end
end
