require "test_helper"

class SiteSettingServiceTest < ActiveSupport::TestCase
  setup do
    SiteSetting.delete_all
  end

  test "defaults returns configured site settings" do
    defaults = SiteSettingService.defaults

    assert_equal "テスト環境の説明", defaults[:top_page_description]
    assert_equal "", defaults[:default_og_image]
    assert_equal %i[top_page_description default_og_image], defaults.keys
  end

  test "get returns value from database when exists" do
    SiteSetting.set("top_page_description", "カスタム説明")

    assert_equal "カスタム説明", SiteSettingService.get("top_page_description")
    assert_equal "カスタム説明", SiteSettingService.get(:top_page_description)
  end

  test "get returns configured default when not in database" do
    assert_equal "テスト環境の説明", SiteSettingService.get(:top_page_description)
  end

  test "get returns nil when key does not exist in defaults" do
    assert_nil SiteSettingService.get(:nonexistent_key)
  end

  test "set saves value to database" do
    SiteSettingService.set(:top_page_description, "新しい説明")

    setting = SiteSetting.find_by(name: "top_page_description")
    assert_equal "新しい説明", setting.value
  end

  test "all_settings returns only configurable default keys" do
    SiteSettingService.set(:top_page_description, "カスタム説明")

    assert_equal({
      top_page_description: "カスタム説明",
      default_og_image: ""
    }, SiteSettingService.all_settings)
  end

  test "update_settings updates valid settings and ignores removed keys" do
    SiteSettingService.update_settings(
      top_page_description: "一括更新した説明",
      site_title: "更新されないタイトル",
      copyright: "更新されない著作権者"
    )

    assert_equal "一括更新した説明", SiteSetting.get("top_page_description")
    assert_nil SiteSetting.find_by(name: "site_title")
    assert_nil SiteSetting.find_by(name: "copyright")
  end

  test "update_settings accepts string keys" do
    SiteSettingService.update_settings("top_page_description" => "文字列キーの更新")

    assert_equal "文字列キーの更新", SiteSetting.get("top_page_description")
  end

  test "reset_to_defaults sets remaining settings" do
    SiteSetting.set("top_page_description", "カスタム説明")

    SiteSettingService.reset_to_defaults!

    assert_equal "テスト環境の説明", SiteSetting.get("top_page_description")
    assert_equal "", SiteSetting.get("default_og_image")
    assert_equal 2, SiteSetting.count
  end
end
