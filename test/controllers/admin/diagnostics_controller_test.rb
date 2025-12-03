require "test_helper"

class Admin::DiagnosticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:admin)
    post admin_login_path, params: { email: @admin.email, password: "password123" }
  end

  test "should get image_upload_check" do
    get admin_diagnostics_image_upload_check_path
    assert_response :success
  end

  test "image_upload_check returns JSON with diagnostics" do
    get admin_diagnostics_image_upload_check_path
    assert_response :success

    json = JSON.parse(response.body)
    assert_includes json.keys, "environment"
    assert_includes json.keys, "vips_available"
    assert_includes json.keys, "gcs_configured"
    assert_includes json.keys, "timestamp"
  end

  test "image_upload_check returns correct environment" do
    get admin_diagnostics_image_upload_check_path
    json = JSON.parse(response.body)

    assert_equal "test", json["environment"]
  end

  test "image_upload_check includes vips status" do
    get admin_diagnostics_image_upload_check_path
    json = JSON.parse(response.body)

    assert_not_nil json["vips_available"]
  end

  test "image_upload_check includes gcs configuration in development" do
    get admin_diagnostics_image_upload_check_path
    json = JSON.parse(response.body)

    assert_equal "test", json["gcs_configured"]["status"]
    assert_equal "GCS not required in test", json["gcs_configured"]["message"]
    assert_equal false, json["gcs_configured"]["project_id"]
    assert_equal false, json["gcs_configured"]["bucket"]
    assert_equal false, json["gcs_configured"]["credentials"]
  end

  test "requires authentication" do
    delete admin_logout_path
    get admin_diagnostics_image_upload_check_path
    assert_redirected_to admin_login_path
  end
end
