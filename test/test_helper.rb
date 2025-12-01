if ENV["COVERAGE"] || ENV["CI"]
  require "simplecov"
  require "simplecov_json_formatter"

  SimpleCov.start "rails" do
    enable_coverage :branch
    add_filter %w[config/ test/ vendor/]
    track_files "app/**/*.rb"
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter
    ])
  end
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

module TestConfig
  TEST_ADMIN_PASSWORD = ENV.fetch("TEST_ADMIN_PASSWORD", "test_secure_password_#{Rails.env}")
  TEST_ADMIN_EMAIL = ENV.fetch("TEST_ADMIN_EMAIL", "admin@example.com")
  TEST_ADMIN_USER_ID = ENV.fetch("TEST_ADMIN_USER_ID", "admin123")
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
    include TestConfig
  end
end

class ActionDispatch::IntegrationTest
  def login_as(admin)
    post admin_login_path, params: { email: admin.email, password: "password123" }
    assert_response :redirect
    follow_redirect!
  end
end
