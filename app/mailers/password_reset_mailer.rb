class PasswordResetMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.password_reset_mailer.reset_email.subject
  #
  def reset_email(admin)
    @admin = admin
    @reset_url = admin_password_reset_url(token: @admin.password_reset_token)

    mail(
      to: @admin.email,
      subject: "パスワードリセットのお知らせ"
    )
  end
end
