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
    SiteSetting.set("top_page_description", "テスト説明文")
    SiteSetting.set("copyright", "© 2025 テストブログ")
    
    assert_equal "テストブログ", SiteSetting.site_title
    assert_equal "https://example.com/image.jpg", SiteSetting.default_og_image
    assert_equal "テスト説明文", SiteSetting.top_page_description
    assert_equal "© 2025 テストブログ", SiteSetting.copyright
  end

  test "should return default values for convenience methods" do
    # 設定が存在しない場合のデフォルト値
    assert_equal "マチダのブログ", SiteSetting.site_title
    assert_equal "マチダのブログへようこそ", SiteSetting.top_page_description
    assert_equal "© #{Date.current.year} マチダのブログ. All rights reserved.", SiteSetting.copyright_text
    assert_nil SiteSetting.default_og_image
  end
end