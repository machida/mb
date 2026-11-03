class ApplicationMailer < ActionMailer::Base
  default from: -> { MailDeliverySettings.new.from }
  layout "mailer"
end
