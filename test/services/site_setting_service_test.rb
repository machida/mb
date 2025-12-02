require "test_helper"

class SiteSettingServiceTest < ActiveSupport::TestCase
  setup do
    SiteSetting.delete_all
  end

  test "defaults returns configured site settings" do
    defaults = SiteSettingService.defaults

    assert_equal "テストブログ", defaults[:site_title]
    assert_equal "テスト環境の説明", defaults[:top_page_description]
    assert_equal "テストブログ", defaults[:copyright]
    assert_equal "", defaults[:default_og_image]
    assert_equal "", defaults[:hero_background_image]
    assert_equal "white", defaults[:hero_text_color]
  end

  test "get returns value from database when exists" do
    SiteSetting.set("site_title", "カスタムタイトル")

    assert_equal "カスタムタイトル", SiteSettingService.get("site_title")
    assert_equal "カスタムタイトル", SiteSettingService.get(:site_title)
  end

  test "get returns default value when not in database" do
    result = SiteSettingService.get(:site_title)

    assert_equal "テストブログ", result
  end

  test "get returns nil when key does not exist in defaults" do
    result = SiteSettingService.get(:nonexistent_key)

    assert_nil result
  end

  test "set saves value to database" do
    SiteSettingService.set(:site_title, "新しいタイトル")

    setting = SiteSetting.find_by(name: "site_title")
    assert_equal "新しいタイトル", setting.value
  end

  test "set accepts both string and symbol keys" do
    SiteSettingService.set("site_title", "文字列キー")
    SiteSettingService.set(:copyright, "シンボルキー")

    assert_equal "文字列キー", SiteSetting.find_by(name: "site_title").value
    assert_equal "シンボルキー", SiteSetting.find_by(name: "copyright").value
  end

  test "all_settings returns hash with all default keys" do
    SiteSettingService.set(:site_title, "カスタム")

    all = SiteSettingService.all_settings

    assert_kind_of Hash, all
    assert_equal "カスタム", all[:site_title]
    assert_equal "テスト環境の説明", all[:top_page_description]
    assert_includes all.keys, :site_title
    assert_includes all.keys, :top_page_description
    assert_includes all.keys, :copyright
    assert_includes all.keys, :default_og_image
    assert_includes all.keys, :hero_background_image
    assert_includes all.keys, :hero_text_color
  end

  test "update_settings updates multiple valid settings" do
    params = {
      site_title: "一括更新タイトル",
      copyright: "一括更新コピーライト"
    }

    SiteSettingService.update_settings(params)

    assert_equal "一括更新タイトル", SiteSetting.get("site_title")
    assert_equal "一括更新コピーライト", SiteSetting.get("copyright")
  end

  test "update_settings ignores invalid keys not in defaults" do
    params = {
      site_title: "有効なキー",
      invalid_key: "無効なキー"
    }

    SiteSettingService.update_settings(params)

    assert_equal "有効なキー", SiteSetting.get("site_title")
    assert_nil SiteSetting.find_by(name: "invalid_key")
  end

  test "update_settings accepts string keys" do
    params = {
      "site_title" => "文字列キーの更新",
      "copyright" => "文字列キーのコピーライト"
    }

    SiteSettingService.update_settings(params)

    assert_equal "文字列キーの更新", SiteSetting.get("site_title")
    assert_equal "文字列キーのコピーライト", SiteSetting.get("copyright")
  end

  test "reset_to_defaults! sets all settings to default values" do
    SiteSetting.set("site_title", "カスタム")
    SiteSetting.set("copyright", "カスタムコピーライト")

    SiteSettingService.reset_to_defaults!

    assert_equal "テストブログ", SiteSetting.get("site_title")
    assert_equal "テストブログ", SiteSetting.get("copyright")
    assert_equal "", SiteSetting.get("default_og_image")
    assert_equal "", SiteSetting.get("hero_background_image")
    assert_equal "white", SiteSetting.get("hero_text_color")
  end

  test "reset_to_defaults! creates settings if they don't exist" do
    SiteSetting.delete_all

    SiteSettingService.reset_to_defaults!

    assert_equal 6, SiteSetting.count
    assert_equal "テストブログ", SiteSetting.get("site_title")
  end
end
