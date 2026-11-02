require "test_helper"

class MailDeliverySettingsTest < ActiveSupport::TestCase
  test "environment overrides credentials including the sender" do
    settings = MailDeliverySettings.new(
      env: { "SMTP_ADDRESS" => "smtp.example.org", "SMTP_PORT" => "2525",
             "SMTP_USER_NAME" => "env@example.org", "SMTP_PASSWORD" => "env-secret",
             "SMTP_AUTHENTICATION" => "login", "MAILER_FROM" => "sender@example.org" },
      credentials: { smtp: { address: "old.example.org", user_name: "old@example.org", password: "old-secret" } }
    )

    assert_equal "smtp.example.org", settings.smtp[:address]
    assert_equal 2525, settings.smtp[:port]
    assert_equal "env@example.org", settings.smtp[:user_name]
    assert_equal "env-secret", settings.smtp[:password]
    assert_equal "login", settings.smtp[:authentication]
    assert_equal "sender@example.org", settings.from
  end

  test "credentials alone configure Gmail and sender without public personal data" do
    settings = MailDeliverySettings.new(env: {}, credentials: {
      smtp: { user_name: "user@example.org", password: "app-secret", from: "sender@example.org" }
    })

    assert_equal "smtp.gmail.com", settings.smtp[:address]
    assert_equal 587, settings.smtp[:port]
    assert settings.smtp[:enable_starttls_auto]
    assert_equal "app-secret", settings.smtp[:password]
    assert_equal "sender@example.org", settings.from
  end

  test "sender defaults to SMTP account when no explicit sender is configured" do
    settings = MailDeliverySettings.new(env: {}, credentials: { smtp: { user_name: "user@example.org" } })
    assert_equal "user@example.org", settings.from
  end

  test "implicit TLS uses port 465 and disables STARTTLS" do
    settings = MailDeliverySettings.new(env: { "SMTP_SSL" => "true" }, credentials: {})
    assert settings.smtp[:ssl]
    assert_equal 465, settings.smtp[:port]
    assert_not settings.smtp[:enable_starttls_auto]
  end

  test "false TLS string overrides credentials" do
    settings = MailDeliverySettings.new(env: { "SMTP_SSL" => "false" }, credentials: { smtp: { ssl: true } })
    assert_not settings.smtp[:ssl]
    assert settings.smtp[:enable_starttls_auto]
  end

  test "invalid port fails without exposing credentials" do
    settings = MailDeliverySettings.new(env: { "SMTP_PORT" => "invalid", "SMTP_PASSWORD" => "secret" }, credentials: {})
    error = assert_raises(ArgumentError) { settings.smtp }
    assert_not_includes error.message, "secret"
  end
end
