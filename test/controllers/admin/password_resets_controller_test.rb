require "test_helper"

class Admin::PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:admin)
  end

  test "should get new" do
    get new_admin_password_reset_path
    assert_response :success
    assert_select "input[type=email]"
  end

  test "should create password reset for existing email" do
    assert_emails 1 do
      post admin_password_resets_path, params: { email: @admin.email }
    end
    
    assert_redirected_to admin_login_path
    assert flash[:notice].include?("パスワードリセット用のメールを送信しました")
    
    @admin.reload
    assert @admin.password_reset_token.present?
    assert @admin.password_reset_sent_at.present?
  end

  test "should not reveal non-existing email" do
    assert_emails 0 do
      post admin_password_resets_path, params: { email: "nonexistent@example.com" }
    end
    
    assert_redirected_to admin_login_path
    assert flash[:notice].include?("パスワードリセット用のメールを送信しました")
  end

  test "should show password reset form with valid token" do
    @admin.generate_password_reset_token
    @admin.reload
    token = @admin.password_reset_token
    
    get admin_password_reset_path(token)
    assert_response :success
    assert_select "input[type=password]", 2
  end

  test "should redirect with invalid token" do
    get admin_password_reset_path("invalid_token")
    assert_redirected_to admin_login_path
    assert flash[:alert].include?("無効なリンクです")
  end

  test "should update password with valid token and matching passwords" do
    @admin.generate_password_reset_token
    @admin.reload
    token = @admin.password_reset_token
    old_password_digest = @admin.password_digest
    
    patch admin_password_reset_path(token), params: {
      admin: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    
    assert_redirected_to root_path
    assert flash[:notice].include?("パスワードが正常に変更されました")
    
    # セッションに管理者IDが設定されていることを確認（自動ログイン）
    assert_equal @admin.id, session[:admin_id]
    
    @admin.reload
    assert_not_equal old_password_digest, @admin.password_digest
    assert_not_equal token, @admin.password_reset_token
    assert_nil @admin.password_reset_sent_at
    assert @admin.password_changed_at.present?
  end

  test "should not update password with mismatched passwords" do
    @admin.generate_password_reset_token
    @admin.reload
    token = @admin.password_reset_token
    
    patch admin_password_reset_path(token), params: {
      admin: {
        password: "newpassword123",
        password_confirmation: "differentpassword"
      }
    }
    
    assert_response :unprocessable_content
    assert flash[:alert].include?("パスワードと確認用パスワードが一致しません")
  end

  test "should not update password with short password" do
    @admin.generate_password_reset_token
    @admin.reload
    token = @admin.password_reset_token

    patch admin_password_reset_path(token), params: {
      admin: {
        password: "short",
        password_confirmation: "short"
      }
    }

    assert_response :unprocessable_content
    assert flash[:alert].include?("パスワードは8文字以上で設定してください")
  end

  test "should not update password with blank password" do
    @admin.generate_password_reset_token
    @admin.reload
    token = @admin.password_reset_token

    patch admin_password_reset_path(token), params: {
      admin: {
        password: "",
        password_confirmation: ""
      }
    }

    assert_response :unprocessable_content
    assert flash[:alert].include?("パスワードを入力してください")
  end

  test "should handle reset_password failure" do
    @admin.generate_password_reset_token
    @admin.reload
    token = @admin.password_reset_token

    # Stub reset_password to return false
    Admin.any_instance.stubs(:reset_password).returns(false)

    patch admin_password_reset_path(token), params: {
      admin: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }

    assert_response :unprocessable_content
    assert flash[:alert].include?("パスワードの変更に失敗しました")
  end
end