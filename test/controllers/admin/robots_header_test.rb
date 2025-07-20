require "test_helper"

class Admin::RobotsHeaderTest < ActionDispatch::IntegrationTest
  def setup
    @admin = Admin.create!(
      email: "test_robots@example.com",
      user_id: "test_robots",
      password: "password123",
      password_confirmation: "password123",
      password_changed_at: Time.current
    )
  end

  test "admin pages include X-Robots-Tag header" do
    # ログインページでX-Robots-Tagヘッダーをテスト
    get "/admin/login"
    assert_response :success
    assert_equal "noindex, nofollow, noarchive, nosnippet, nocache", response.headers["X-Robots-Tag"]
  end

  test "admin dashboard includes X-Robots-Tag header after login" do
    # ログイン後の管理画面でX-Robots-Tagヘッダーをテスト
    sign_in_as(@admin)
    get "/admin/articles"
    assert_response :success
    assert_equal "noindex, nofollow, noarchive, nosnippet, nocache", response.headers["X-Robots-Tag"]
  end

  test "admin site settings includes X-Robots-Tag header" do
    sign_in_as(@admin)
    get "/admin/site-settings"
    assert_response :success
    assert_equal "noindex, nofollow, noarchive, nosnippet, nocache", response.headers["X-Robots-Tag"]
  end

  test "public pages do not include X-Robots-Tag header" do
    # 公開ページにはX-Robots-Tagヘッダーが設定されていないことを確認
    get "/"
    assert_response :success
    assert_nil response.headers["X-Robots-Tag"]
  end

  private

  def sign_in_as(admin)
    post "/admin/login", params: { email: admin.email, password: "password123" }
    follow_redirect!
  end
end