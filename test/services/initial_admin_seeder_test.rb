require "test_helper"

class InitialAdminSeederTest < ActiveSupport::TestCase
  setup { Admin.delete_all }

  test "production refuses missing or short credentials without creating an administrator" do
    [ {}, { "INITIAL_ADMIN_EMAIL" => "owner@example.com", "INITIAL_ADMIN_USER_ID" => "owner",
             "INITIAL_ADMIN_PASSWORD" => "short" } ].each do |env|
      assert_no_difference "Admin.count" do
        assert_raises(ArgumentError) { InitialAdminSeeder.call(environment: "production", env: env) }
      end
    end
  end

  test "production creates the explicitly configured administrator" do
    env = { "INITIAL_ADMIN_EMAIL" => "owner@example.com", "INITIAL_ADMIN_USER_ID" => "owner",
            "INITIAL_ADMIN_PASSWORD" => "a-long-initial-password" }
    assert_difference "Admin.count", 1 do
      InitialAdminSeeder.call(environment: "production", env: env)
    end
    assert Admin.find_by!(email: env["INITIAL_ADMIN_EMAIL"]).authenticate(env["INITIAL_ADMIN_PASSWORD"])
  end

  test "existing administrator is preserved and no default account is added" do
    admin = Admin.create!(email: "owner@example.com", user_id: "owner", password: "existing-password")
    assert_no_difference "Admin.count" do
      InitialAdminSeeder.call(environment: "production", env: {})
    end
    assert admin.reload.authenticate("existing-password")
    assert_nil Admin.find_by(email: "admin@example.com")
  end

  test "development creates a valid local account" do
    InitialAdminSeeder.call(environment: "development", env: {})
    assert Admin.find_by!(email: "admin@example.com").authenticate("development-password")
  end
end
