require "test_helper"

class AuthenticationSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:admin)
  end

  test "password change invalidates another browser but keeps the changing browser signed in" do
    other = signed_in_browser
    login_as(@admin)
    patch admin_password_path, params: {
      admin: { password: "changed-password-123", password_confirmation: "changed-password-123" }
    }
    get edit_admin_profile_path
    assert_response :success
    other.get edit_admin_profile_path
    other.assert_redirected_to admin_login_path
  end

  test "password reset invalidates an existing browser and the used reset link" do
    other = signed_in_browser
    @admin.generate_password_reset_token
    token = @admin.reload.password_reset_token
    patch admin_password_reset_path(token), params: {
      admin: { password: "changed-password-123", password_confirmation: "changed-password-123" }
    }
    get edit_admin_profile_path
    assert_response :success
    other.get edit_admin_profile_path
    other.assert_redirected_to admin_login_path
    get admin_password_reset_path(token)
    assert_redirected_to admin_login_path
  end

  test "failed password change preserves other sessions" do
    other = signed_in_browser
    login_as(@admin)
    patch admin_password_path, params: { admin: { password: "short", password_confirmation: "short" } }
    assert_response :unprocessable_content
    other.get edit_admin_profile_path
    other.assert_response :success
  end

  test "login attempts are limited and recover after the window" do
    with_rate_limit_store(Admin::SessionsController) do
      10.times do
        post admin_login_path, params: { email: @admin.email, password: "incorrect" }
        assert_response :unprocessable_content
      end
      post admin_login_path, params: { email: @admin.email, password: "password123" }
      assert_response :too_many_requests
      assert_nil session[:admin_id]
      travel 3.minutes + 1.second do
        post admin_login_path, params: { email: @admin.email, password: "password123" }
        assert_redirected_to root_path
      end
    end
  end

  test "reset request limit prevents additional email and token rotation" do
    with_rate_limit_store(Admin::PasswordResetsController) do
      assert_emails 5 do
        5.times { post admin_password_resets_path, params: { email: @admin.email } }
      end
      token = @admin.reload[:password_reset_token]
      assert_no_emails do
        post admin_password_resets_path, params: { email: @admin.email }
      end
      assert_response :too_many_requests
      assert_equal token, @admin.reload[:password_reset_token]
    end
  end

  test "missing password digests invalidate sessions instead of raising" do
    login_as(@admin)
    @admin.update_column(:password_digest, nil)
    get edit_admin_profile_path
    assert_redirected_to admin_login_path
    assert_nil session[:admin_id]
  end

  test "CSRF token refresh requires authentication and cannot be cached" do
    get admin_csrf_token_path
    assert_redirected_to admin_login_path
    login_as(@admin)
    get admin_csrf_token_path
    assert_response :success
    assert_equal "no-store", response.headers["Cache-Control"]
    assert response.parsed_body["token"].present?
    @admin.update!(password: "changed-password-123")
    get admin_csrf_token_path
    assert_redirected_to admin_login_path
  end

  private

  def signed_in_browser
    open_session do |browser|
      browser.post admin_login_path, params: { email: @admin.email, password: "password123" }
      browser.assert_redirected_to root_path
    end
  end

  def with_rate_limit_store(controller)
    # The callback captures the store at class load time; exercise real counters
    # without enabling shared cache state for the rest of the test suite.
    store = controller.cache_store
    memory = ActiveSupport::Cache::MemoryStore.new
    store.define_singleton_method(:increment) do |*args, **options|
      memory.increment(*args, **options)
    end
    yield
  ensure
    store.singleton_class.remove_method(:increment)
  end
end
