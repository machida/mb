require "test_helper"
require "erb"
require "yaml"

class BootstrapDeploymentTest < ActiveSupport::TestCase
  KEYS = %w[INITIAL_ADMIN_EMAIL INITIAL_ADMIN_USER_ID INITIAL_ADMIN_PASSWORD].freeze

  test "bootstrap secrets travel through CI and Kamal without cleartext values" do
    with_bootstrap_env(KEYS.index_with { "test-only-value" }) do
      config = YAML.safe_load(ERB.new(Rails.root.join("config/deploy.yml").read).result)
      workflow = YAML.safe_load(Rails.root.join(".github/workflows/ci.yml").read)
      deploy = workflow.dig("jobs", "deploy", "steps").find { |step| step["name"] == "Deploy with Kamal" }
      KEYS.each do |key|
        assert_includes config.dig("env", "secret"), key
        assert_nil config.dig("env", "clear", key)
        assert_equal "${{ secrets.#{key} }}", deploy.dig("env", key)
        assert_includes Rails.root.join(".kamal/secrets").read, "#{key}=$#{key}"
      end
    end
  end

  test "existing deployments do not require bootstrap secrets" do
    with_bootstrap_env(KEYS.index_with { "" }) do
      config = YAML.safe_load(ERB.new(Rails.root.join("config/deploy.yml").read).result)
      assert_empty config.dig("env", "secret") & KEYS
    end
  end

  private

  def with_bootstrap_env(values)
    previous = ENV.to_h.slice(*KEYS)
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    KEYS.each { |key| ENV[key] = previous[key] }
  end
end
