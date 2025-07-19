require "test_helper"

class Admin::AdminsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:admin)
    @second_admin = admins(:second_admin)
    login_as(@admin)
  end

  test "should get index" do
    get admin_admins_url
    assert_response :success
    assert_select ".spec--admins-list"
    assert_select ".spec--admin-user-id", text: @admin.user_id
  end

  test "should get new" do
    get new_admin_admin_url
    assert_response :success
    assert_select ".spec--admin-form-title"
  end

  test "should create admin" do
    assert_difference("Admin.count", 1) do
      post admin_admins_url, params: {
        admin: {
          email: "test_new_admin@example.com",
          user_id: "test_new_admin",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    
    assert_redirected_to admin_admins_url
    
    new_admin = Admin.find_by(email: "newadmin@example.com")
    assert new_admin
    assert new_admin.needs_password_change?
  end

  test "should not create admin with invalid data" do
    assert_no_difference("Admin.count") do
      post admin_admins_url, params: {
        admin: {
          email: "",
          user_id: "",
          password: "123",
          password_confirmation: "456"
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  test "should show admin" do
    get admin_admin_url(@admin)
    assert_response :success
    assert_select ".spec--admin-user-id", text: @admin.user_id
  end

  test "should destroy admin when not last admin" do
    assert_difference("Admin.count", -1) do
      delete admin_admin_url(@second_admin)
    end
    
    assert_redirected_to admin_admins_url
  end

  test "should not destroy last admin" do
    # 他の管理者を全て削除して、最後の一人にする
    @second_admin.destroy
    Admin.where.not(id: @admin.id).destroy_all
    
    assert_no_difference("Admin.count") do
      delete admin_admin_url(@admin)
    end
    
    assert_redirected_to admin_admins_url
  end

  test "should redirect to confirm_delete when admin has articles" do
    article = Article.create!(
      title: "Test Article",
      body: "Test content",
      author: @second_admin.user_id,
      draft: false
    )
    
    delete admin_admin_url(@second_admin)
    assert_redirected_to admin_admin_url(@second_admin)
  end

  test "should process delete with article transfer" do
    article = Article.create!(
      title: "Test Article",
      body: "Test content",
      author: @second_admin.user_id,
      draft: false
    )
    
    assert_difference("Admin.count", -1) do
      post process_delete_admin_admin_url(@second_admin), params: {
        action_type: "transfer",
        target_admin_id: @admin.id
      }
    end
    
    article.reload
    assert_equal @admin.user_id, article.author
  end

  test "should process delete with article deletion" do
    article = Article.create!(
      title: "Test Article",
      body: "Test content",
      author: @second_admin.user_id,
      draft: false
    )
    
    assert_difference("Admin.count", -1) do
      assert_difference("Article.count", -1) do
        post process_delete_admin_admin_url(@second_admin), params: {
          action_type: "delete_articles"
        }
      end
    end
  end

  test "should logout when deleting self" do
    login_as(@second_admin)
    
    delete admin_admin_url(@second_admin)
    assert_redirected_to admin_login_url
    assert_nil session[:admin_id]
  end
end