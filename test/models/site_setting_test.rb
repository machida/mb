require "test_helper"

class SiteSettingTest < ActiveSupport::TestCase
  def setup
    SiteSetting.destroy_all
    Rails.cache.clear
  end

  test "should create site setting" do
    setting = SiteSetting.create!(name: "test_setting", value: "test_value")
    assert setting.valid?
    assert_equal "test_setting", setting.name
    assert_equal "test_value", setting.value
  end

  test "should validate presence of name and value" do
    setting = SiteSetting.new
    assert_not setting.valid?
    assert_includes setting.errors[:name], "can't be blank"
    assert_includes setting.errors[:value], "can't be blank"
  end

  test "should validate uniqueness of name" do
    SiteSetting.create!(name: "unique_name", value: "value1")
    
    duplicate_setting = SiteSetting.new(name: "unique_name", value: "value2")
    assert_not duplicate_setting.valid?
    assert_includes duplicate_setting.errors[:name], "has already been taken"
  end

  test "should get setting value with default" do
    # 存在しない設定
    assert_equal "default_value", SiteSetting.get("non_existent", "default_value")
    assert_nil SiteSetting.get("non_existent")
    
    # 存在する設定
    SiteSetting.create!(name: "existing_setting", value: "actual_value")
    assert_equal "actual_value", SiteSetting.get("existing_setting", "default_value")
  end

  test "should set setting value" do
    # 新しい設定の作成
    SiteSetting.set("new_setting", "new_value")
    assert_equal "new_value", SiteSetting.get("new_setting")
    
    # 既存の設定の更新
    SiteSetting.set("new_setting", "updated_value")
    assert_equal "updated_value", SiteSetting.get("new_setting")
    
    # データベースでも確認
    setting = SiteSetting.find_by(name: "new_setting")
    assert_equal "updated_value", setting.value
  end

  test "should cache setting values" do
    SiteSetting.create!(name: "cached_setting", value: "cached_value")
    
    # 最初のアクセスでキャッシュに保存
    value1 = SiteSetting.get("cached_setting")
    assert_equal "cached_value", value1
    
    # setメソッドを使うとキャッシュがクリアされる
    SiteSetting.set("cached_setting", "newest_value")
    value2 = SiteSetting.get("cached_setting")
    assert_equal "newest_value", value2
  end

  test "should provide convenience methods" do
    SiteSetting.set("site_title", "テストブログ")
    SiteSetting.set("default_og_image", "https://example.com/image.jpg")
    SiteSetting.set("hero_background_image", "https://example.com/hero.jpg")
    SiteSetting.set("hero_text_color", "black")
    SiteSetting.set("top_page_description", "テスト説明文")
    SiteSetting.set("copyright", "© 2025 テストブログ")
    
    assert_equal "テストブログ", SiteSetting.site_title
    assert_equal "https://example.com/image.jpg", SiteSetting.default_og_image
    assert_equal "https://example.com/hero.jpg", SiteSetting.hero_background_image
    assert_equal "black", SiteSetting.hero_text_color
    assert_equal "テスト説明文", SiteSetting.top_page_description
    assert_equal "© 2025 テストブログ", SiteSetting.copyright
  end

  test "should return default values for convenience methods" do
    # 設定が存在しない場合のデフォルト値
    assert_equal "ブログ", SiteSetting.site_title
    assert_equal "ブログへようこそ。技術やライフスタイルについて書いています。", SiteSetting.top_page_description
    assert_equal "© #{Date.current.year} MB. All rights reserved.", SiteSetting.copyright_text
    assert_nil SiteSetting.default_og_image
    assert_nil SiteSetting.hero_background_image
    assert_equal "white", SiteSetting.hero_text_color
  end

  test "hero text color falls back to white for invalid values" do
    SiteSetting.set("hero_text_color", "purple")
    assert_equal "white", SiteSetting.hero_text_color
  end

  test "default_og_image_url returns same as default_og_image" do
    SiteSetting.set("default_og_image", "https://example.com/og-image.jpg")
    assert_equal "https://example.com/og-image.jpg", SiteSetting.default_og_image_url

    # When no image is set
    SiteSetting.destroy_all
    Rails.cache.clear
    assert_nil SiteSetting.default_og_image_url
  end

  test "author_display_enabled returns boolean" do
    # Default value should be true
    assert_equal true, SiteSetting.author_display_enabled

    # When set to "true"
    SiteSetting.set("author_display_enabled", "true")
    assert_equal true, SiteSetting.author_display_enabled

    # When set to "false"
    SiteSetting.set("author_display_enabled", "false")
    assert_equal false, SiteSetting.author_display_enabled

    # Any other value should be false
    SiteSetting.set("author_display_enabled", "yes")
    assert_equal false, SiteSetting.author_display_enabled
  end

  test "openai_api_key and openai_api_key_configured?" do
    # When not set
    assert_nil SiteSetting.openai_api_key
    assert_equal false, SiteSetting.openai_api_key_configured?

    # When set
    SiteSetting.set("openai_api_key", "sk-test-key-123")
    assert_equal "sk-test-key-123", SiteSetting.openai_api_key
    assert_equal true, SiteSetting.openai_api_key_configured?

    # When set to empty string
    SiteSetting.set("openai_api_key", "")
    assert_equal "", SiteSetting.openai_api_key
    assert_equal false, SiteSetting.openai_api_key_configured?
  end

  test "allows blank value for copyright" do
    setting = SiteSetting.new(name: "copyright", value: "")
    assert setting.valid?, "Copyright should allow blank value"
  end

  test "allows blank value for default_og_image" do
    setting = SiteSetting.new(name: "default_og_image", value: "")
    assert setting.valid?, "default_og_image should allow blank value"
  end

  test "allows blank value for hero_background_image" do
    setting = SiteSetting.new(name: "hero_background_image", value: "")
    assert setting.valid?, "hero_background_image should allow blank value"
  end

  test "allows blank value for openai_api_key" do
    setting = SiteSetting.new(name: "openai_api_key", value: "")
    assert setting.valid?, "openai_api_key should allow blank value"
  end

  test "does not allow blank value for other settings" do
    setting = SiteSetting.new(name: "site_title", value: "")
    assert_not setting.valid?, "site_title should not allow blank value"
    assert_includes setting.errors[:value], "can't be blank"
  end

  test "copyright_text formats correctly" do
    SiteSetting.set("copyright", "My Company")
    expected = "© #{Date.current.year} My Company. All rights reserved."
    assert_equal expected, SiteSetting.copyright_text
  end

  test "copyright_text with default value" do
    expected = "© #{Date.current.year} MB. All rights reserved."
    assert_equal expected, SiteSetting.copyright_text
  end
end
