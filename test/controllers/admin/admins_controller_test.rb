require "test_helper"

class Admin::AdminsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = login_as_admin
    @other_admin = create_other_admin
  end

  teardown do
    logout_admin
  end

  test "should get index" do
    get admin_admins_url
    assert_response :success
    assert_select ".spec--admin-item", count: Admin.count
  end

  test "should get new" do
    get new_admin_admin_url
    assert_response :success
    assert_select ".spec--admin-form"
  end

  test "should create admin with valid params" do
    assert_difference("Admin.count") do
      post admin_admins_url, params: {
        admin: {
          user_id: "new_admin",
          email: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to admin_admins_url
    follow_redirect!
    assert_toast_message("管理者を作成しました")
  end

  test "should not create admin with invalid params" do
    assert_no_difference("Admin.count") do
      post admin_admins_url, params: {
        admin: {
          user_id: "",
          email: "invalid-email",
          password: "short",
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show admin" do
    get admin_admin_url(@other_admin)
    assert_response :success
    assert_select ".spec--admin-user-id", text: @other_admin.user_id
    assert_select ".spec--admin-email", text: @other_admin.email
  end

  test "should get edit" do
    get edit_admin_admin_url(@other_admin)
    assert_response :success
    assert_select ".spec--admin-form"
  end

  test "should update admin with valid params" do
    patch admin_admin_url(@other_admin), params: {
      admin: {
        user_id: "updated_admin",
        email: "updated@example.com"
      }
    }

    assert_redirected_to admin_admins_url
    follow_redirect!
    assert_toast_message("管理者情報を更新しました")
    
    @other_admin.reload
    assert_equal "updated_admin", @other_admin.user_id
    assert_equal "updated@example.com", @other_admin.email
  end

  test "should not update admin with invalid params" do
    original_email = @other_admin.email
    
    patch admin_admin_url(@other_admin), params: {
      admin: {
        email: "invalid-email"
      }
    }

    assert_response :unprocessable_entity
    @other_admin.reload
    assert_equal original_email, @other_admin.email
  end

  test "should destroy other admin" do
    assert_difference("Admin.count", -1) do
      delete admin_admin_url(@other_admin)
    end

    assert_redirected_to admin_admins_url
    follow_redirect!
    assert_toast_message("管理者を削除しました")
  end

  test "should not destroy current admin" do
    current_admin = Admin.find(session[:admin_id])
    
    assert_no_difference("Admin.count") do
      delete admin_admin_url(current_admin)
    end

    assert_redirected_to admin_admins_url
    follow_redirect!
    assert_toast_message("自分自身を削除することはできません")
  end

  test "should require admin authentication for all actions" do
    logout_admin

    assert_admin_authentication_required(admin_admins_url)
    assert_admin_authentication_required(new_admin_admin_url)
    assert_admin_authentication_required(admin_admins_url, :post, { admin: { user_id: "test" } })
    assert_admin_authentication_required(admin_admin_url(@other_admin))
    assert_admin_authentication_required(edit_admin_admin_url(@other_admin))
    assert_admin_authentication_required(admin_admin_url(@other_admin), :patch, { admin: { user_id: "test" } })
    assert_admin_authentication_required(admin_admin_url(@other_admin), :delete)
  end
end