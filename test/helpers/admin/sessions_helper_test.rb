require "test_helper"

class Admin::SessionsHelperTest < ActionView::TestCase
  include Admin::SessionsHelper

  def setup
    Admin.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123", 
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should have access to session helper methods" do
    # The actual session helpers are in ApplicationController
    # This test just verifies the helper module exists and is included
    assert Admin::SessionsHelper.is_a?(Module)
    assert_includes self.class.included_modules, Admin::SessionsHelper
  end

  # Note: The actual authentication logic is tested in ApplicationController
  # and individual controller tests. This helper mainly provides access to
  # those methods in views.
end