class SiteSetting < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :value, presence: true, unless: :allows_blank_value?

  # キャッシュを使って設定値を取得するクラスメソッド
  def self.get(name, default_value = nil)
    Rails.cache.fetch("site_setting_#{name}", expires_in: 1.hour) do
      setting = find_by(name: name)
      setting&.value || default_value
    end
  end

  # 設定値を更新するクラスメソッド
  def self.set(name, value)
    setting = find_or_initialize_by(name: name)
    setting.value = value
    setting.save!
    Rails.cache.delete("site_setting_#{name}")
    setting
  end

  # 便利メソッド
  def self.site_title
    get("site_title", "ブログ")
  end

  def self.default_og_image
    get("default_og_image")
  end

  def self.default_og_image_url
    # アップロード時に既にOGサイズにリサイズされているので、そのまま使用
    default_og_image
  end

  def self.top_page_description
    get("top_page_description", "ブログへようこそ。技術やライフスタイルについて書いています。")
  end

  def self.copyright
    get("copyright", "MB")
  end

  def self.copyright_text
    "© #{Date.current.year} #{copyright}. All rights reserved."
  end

  def self.author_display_enabled
    get("author_display_enabled", "true") == "true"
  end

  def self.openai_api_key
    get("openai_api_key")
  end

  def self.openai_api_key_configured?
    openai_api_key.present?
  end

  private

  def allows_blank_value?
    name.in?(%w[copyright default_og_image openai_api_key])
  end
end
