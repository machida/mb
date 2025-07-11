# Site Settings Configuration
Rails.application.configure do
  # デフォルト値の設定
  config.site_settings_defaults = {
    site_title: "マチダのブログ",
    top_page_description: "プログラミングと日常の雑記ブログ",
    copyright: "マチダのブログ",
    default_og_image: ""
  }

  # 環境別設定
  case Rails.env
  when 'test'
    config.site_settings_defaults.merge!(
      site_title: "テストブログ",
      top_page_description: "テスト環境の説明",
      copyright: "テストブログ"
    )
  when 'development'
    config.site_settings_defaults.merge!(
      site_title: "開発環境 - マチダのブログ",
      top_page_description: "開発環境での動作確認用",
      copyright: "開発環境"
    )
  when 'production'
    # 本番環境では設定値をそのまま使用
  end
end

# アプリケーション起動時にデフォルト値を設定
Rails.application.config.after_initialize do
  next unless ActiveRecord::Base.connection.data_source_exists?('site_settings')

  Rails.application.config.site_settings_defaults.each do |key, value|
    SiteSetting.set(key.to_s, value) unless SiteSetting.exists?(key: key.to_s)
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
  # データベースが存在しない場合やテーブルが存在しない場合はスキップ
  Rails.logger.info "Skipping site settings initialization - database not ready"
end