require "test_helper"

class Admin::ProfilesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Clear all test data
    Article.destroy_all
    Admin.destroy_all
    
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def login_as_admin
    post admin_login_path, params: { email: @admin.email, password: "password123" }
  end

  test "should redirect to login when not authenticated" do
    get edit_admin_profile_path
    assert_redirected_to admin_login_path
  end

  test "should get edit when authenticated" do
    login_as_admin
    get edit_admin_profile_path
    assert_response :success
    assert_select ".spec--profile-edit-title", "プロフィール編集"
  end

  test "should update email and user_id" do
    login_as_admin
    
    patch admin_profile_path, params: {
      admin: {
        email: "new@example.com",
        user_id: "newuser123"
      }
    }
    
    @admin.reload
    assert_equal "new@example.com", @admin.email
    assert_equal "newuser123", @admin.user_id
    assert_redirected_to edit_admin_profile_path
  end


  test "should not update with invalid email" do
    login_as_admin
    
    patch admin_profile_path, params: {
      admin: {
        email: "",
        user_id: @admin.user_id
      }
    }
    
    assert_response :unprocessable_content
    assert_select ".spec--error-messages"
  end

  test "should not update with invalid user_id" do
    login_as_admin
    
    patch admin_profile_path, params: {
      admin: {
        email: @admin.email,
        user_id: ""
      }
    }
    
    assert_response :unprocessable_content
    assert_select ".spec--error-messages"
  end


  test "should not update with duplicate email" do
    # Create another admin
    other_admin = Admin.create!(
      email: "other@example.com",
      user_id: "other123",
      password: "password123",
      password_confirmation: "password123"
    )
    
    login_as_admin
    
    patch admin_profile_path, params: {
      admin: {
        email: other_admin.email,
        user_id: @admin.user_id
      }
    }
    
    assert_response :unprocessable_content
    assert_select ".spec--error-messages"
  end

  test "should not update with duplicate user_id" do
    # Create another admin
    other_admin = Admin.create!(
      email: "other@example.com",
      user_id: "other123",
      password: "password123",
      password_confirmation: "password123"
    )
    
    login_as_admin
    
    patch admin_profile_path, params: {
      admin: {
        email: @admin.email,
        user_id: other_admin.user_id
      }
    }
    
    assert_response :unprocessable_content
    assert_select ".spec--error-messages"
  end
end