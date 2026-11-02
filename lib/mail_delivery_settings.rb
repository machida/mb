class MailDeliverySettings
  def initialize(env: ENV, credentials: Rails.application.credentials)
    @env = env
    @credentials = credentials
  end

  def from
    @env["MAILER_FROM"].presence || @credentials.dig(:smtp, :from).presence ||
      setting(:user_name).presence || "noreply@example.com"
  end

  def smtp
    ssl = ActiveModel::Type::Boolean.new.cast(setting(:ssl, false))
    {
      address: setting(:address, "smtp.gmail.com"),
      port: Integer(setting(:port, ssl ? 465 : 587).to_s, 10),
      user_name: setting(:user_name),
      password: setting(:password),
      authentication: setting(:authentication, "plain"),
      ssl: ssl,
      enable_starttls_auto: !ssl,
      domain: @env.fetch("APP_HOST", "example.com"),
      open_timeout: 5,
      read_timeout: 5
    }
  end

  private

  def setting(key, default = nil)
    value = @env["SMTP_#{key.to_s.upcase}"].presence
    value = @credentials.dig(:smtp, key) if value.nil?
    value.nil? ? default : value
  end
end
