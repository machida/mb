require "test_helper"

class Admin::SiteSettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    Admin.destroy_all
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123",
      password_confirmation: "password123"
    )
    
    post admin_login_path, params: { email: @admin.email, password: "password123" }
  end

  test "should show site settings page" do
    get admin_site_settings_path
    assert_response :success
    assert_select ".spec--site-settings-title", "サイト設定"
    assert_select ".spec--default-og-image-input"
    assert_select ".spec--top-page-description-input"
    # Check for thumbnail upload components
    assert_select "div[data-controller='thumbnail-upload']"
    assert_select ".spec--site-title-input", count: 0
    assert_select ".spec--copyright-input", count: 0
    assert_select ".spec--hero-background-image-input", count: 0
    assert_select ".spec--hero-text-color-white", count: 0
  end

  test "should update site settings" do
    patch admin_site_settings_path, params: {
      site_settings: {
        default_og_image: "https://example.com/new-image.jpg",
        top_page_description: "新しい説明文です"
      }
    }
    
    assert_redirected_to admin_site_settings_path
    follow_redirect!
    assert_match "サイト設定を更新しました", response.body
    
    # 設定値が更新されているか確認
    assert_equal "https://example.com/new-image.jpg", SiteSetting.default_og_image
    assert_equal "新しい説明文です", SiteSetting.top_page_description
  end

  test "should not allow access without login" do
    delete admin_logout_path

    get admin_site_settings_path
    assert_redirected_to admin_login_path

    patch admin_site_settings_path, params: {
      site_settings: {
        top_page_description: "Test"
      }
    }
    assert_redirected_to admin_login_path
  end

  test "should clear default_og_image when blank" do
    SiteSetting.set("default_og_image", "https://example.com/old-image.jpg")

    patch admin_site_settings_path, params: {
      site_settings: {
        default_og_image: ""
      }
    }

    assert_equal "", SiteSetting.default_og_image
  end

  test "should preserve existing images when updating other site settings" do
    SiteSetting.set("default_og_image", "https://example.com/og-image.jpg")

    patch admin_site_settings_path, params: {
      site_settings: {
        default_og_image: SiteSetting.default_og_image,
        top_page_description: "説明文だけ更新"
      }
    }

    assert_redirected_to admin_site_settings_path
    assert_equal "https://example.com/og-image.jpg", SiteSetting.default_og_image
    assert_equal "説明文だけ更新", SiteSetting.top_page_description
  end

  test "should update author_display_enabled" do
    patch admin_site_settings_path, params: {
      site_settings: {
        author_display_enabled: "false"
      }
    }

    assert_equal "false", SiteSetting.get("author_display_enabled")
  end

  test "should update openai_api_key" do
    patch admin_site_settings_path, params: {
      site_settings: {
        openai_api_key: "sk-test-key"
      }
    }

    assert_equal "sk-test-key", SiteSetting.openai_api_key
  end

  test "should upload image successfully" do
    # Create a test image file
    require "image_processing/vips"
    image = Vips::Image.black(100, 100)
    temp_file = Tempfile.new(["test_image", ".jpg"])
    temp_file.close
    image.write_to_file(temp_file.path)

    uploaded_file = Rack::Test::UploadedFile.new(
      temp_file.path,
      "image/jpeg",
      original_filename: "test.jpg"
    )

    Rails.env.stubs(:production?).returns(false)

    post admin_site_settings_upload_image_path, params: { image: uploaded_file, upload_type: "thumbnail" }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["url"]
    assert json["markdown"]

    temp_file.unlink
  end

  test "should return error when no image provided" do
    post admin_site_settings_upload_image_path, params: {}

    assert_response 422
    json = JSON.parse(response.body)
    assert_equal "画像ファイルが選択されていません", json["error"]
  end

  test "should handle upload error gracefully" do
    uploaded_file = Rack::Test::UploadedFile.new(
      StringIO.new("not an image"),
      "text/plain",
      original_filename: "test.txt"
    )

    post admin_site_settings_upload_image_path, params: { image: uploaded_file }

    assert_response 422
    json = JSON.parse(response.body)
    assert json["error"]
  end

  test "should handle update exception" do
    # Force an exception during update
    SiteSetting.stubs(:set).raises(StandardError.new("Test error"))

    patch admin_site_settings_path, params: {
      site_settings: {
        top_page_description: "Test"
      }
    }

    assert_redirected_to admin_site_settings_path
    follow_redirect!
    assert_match "設定の更新に失敗しました", response.body
  end
end
