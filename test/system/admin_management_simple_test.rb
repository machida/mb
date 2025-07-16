require "test_helper"

class AdminManagementSimpleTest < ActionDispatch::IntegrationTest
  setup do
    @admin = login_as_admin
    @other_admin = create_other_admin
  end

  teardown do
    logout_admin
  end

  test "admin can access admin management page" do
    get admin_admins_path
    assert_response :success
    assert_select ".spec--admin-item", count: Admin.count
    assert_select ".spec--add-admin-btn"
  end

  test "admin can view new admin form" do
    get new_admin_admin_path
    assert_response :success
    assert_select ".spec--admin-form"
    assert_admin_form_fields
  end

  test "admin management link exists in navigation" do
    get admin_articles_path
    assert_response :success
    assert_select ".spec--admin-management-link"
  end

  test "admin can view other admin details" do
    get admin_admin_path(@other_admin)
    assert_response :success
    assert_admin_item_present(@other_admin)
  end

  test "admin can view edit form for other admin" do
    get edit_admin_admin_path(@other_admin)
    assert_response :success
    assert_select ".spec--admin-form"
    assert_admin_form_fields
    assert_select ".spec--user-id-input[value=?]", @other_admin.user_id
    assert_select ".spec--email-input[value=?]", @other_admin.email
  end
end