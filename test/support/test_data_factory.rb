# test/support/test_data_factory.rb
module TestDataFactory
  extend self
  
  # SequenceGeneratorでユニーク性を保証
  class SequenceGenerator
    @counters = Hash.new(0)
    @mutex = Mutex.new
    
    def self.next(name)
      @mutex.synchronize do
        @counters[name] += 1
      end
    end
    
    def self.reset(name = nil)
      @mutex.synchronize do
        if name
          @counters[name] = 0
        else
          @counters.clear
        end
      end
    end
  end
  
  # テストデータのビルダーメソッド（まだ保存しない）
  def build_admin(attributes = {})
    sequence = SequenceGenerator.next(:admin)
    config = TestConfiguration.test_data_config
    {
      email: "admin#{sequence}@example.com",
      user_id: "admin#{sequence}",
      password: config[:admin_password],
      password_confirmation: config[:admin_password]
    }.merge(attributes)
  end
  
  def build_article(attributes = {})
    sequence = SequenceGenerator.next(:article)
    admin = attributes.delete(:admin)
    
    {
      title: "Test Article #{sequence}",
      body: "# Test Content #{sequence}\n\nThis is test content for article #{sequence}.",
      summary: "Test summary for article #{sequence}",
      author: admin&.user_id || "admin1",
      draft: false
    }.merge(attributes)
  end
  
  def build_site_setting(attributes = {})
    sequence = SequenceGenerator.next(:site_setting)
    {
      name: "test_setting_#{sequence}",
      value: "test_value_#{sequence}"
    }.merge(attributes)
  end
  
  # テストデータの作成メソッド（保存する）
  def create_admin(attributes = {})
    Admin.create!(build_admin(attributes))
  end

  def create_article(attributes = {})
    admin = attributes.delete(:admin) || create_admin
    Article.create!(build_article(attributes.merge(author: admin.user_id)))
  end

  def create_draft_article(attributes = {})
    create_article(attributes.merge(draft: true))
  end
  
  def create_published_article(attributes = {})
    create_article(attributes.merge(draft: false))
  end
  
  def create_site_setting(attributes = {})
    SiteSetting.create!(build_site_setting(attributes))
  end

  # 関連データを含む複合オブジェクトの作成
  def create_admin_with_articles(admin_attrs = {}, article_count: 3)
    admin = create_admin(admin_attrs)
    articles = article_count.times.map do |i|
      create_article(
        admin: admin,
        title: "Article #{i + 1} by #{admin.user_id}",
        draft: i.even? # 偶数番目は下書き
      )
    end
    
    { admin: admin, articles: articles }
  end

  # テストデータのクリーンアップ
  def clear_test_data
    # 関連テーブルの順序を考慮して削除
    Article.delete_all
    Admin.delete_all
    SiteSetting.delete_all
    
    # カウンターもリセット
    SequenceGenerator.reset
  end
  
  # 高速なクリーンアップ（トランケート使用）
  def truncate_test_data
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 0") if adapter_supports_foreign_keys?
    
    %w[articles admins site_settings].each do |table|
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table}")
    end
    
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 1") if adapter_supports_foreign_keys?
    
    SequenceGenerator.reset
  end

  # テスト用画像のキャッシュ機能付き作成
  def create_test_image(filename: "test.jpg", use_cache: true)
    cache_key = "test_image_#{filename}"
    
    if use_cache && (@image_cache ||= {})[cache_key]
      return @image_cache[cache_key].dup
    end
    
    require "image_processing/vips"
    vips_image = Vips::Image.black(100, 100)
    temp_file = Tempfile.new([filename.split('.').first, ".#{filename.split('.').last}"])
    temp_file.close
    vips_image.write_to_file(temp_file.path)
    
    image_data = File.binread(temp_file.path)
    uploaded_file = Rack::Test::UploadedFile.new(
      StringIO.new(image_data),
      "image/jpeg",
      original_filename: filename
    )
    
    result = { uploaded_file: uploaded_file, temp_file: temp_file }
    
    if use_cache
      (@image_cache ||= {})[cache_key] = result.dup
    end
    
    result
  end
  
  # テストスイート終了時のクリーンアップ
  def cleanup_image_cache
    @image_cache&.each_value do |cached_image|
      cached_image[:temp_file]&.unlink rescue nil
    end
    @image_cache&.clear
  end
  
  # トランザクション内でのテストデータ管理
  def with_test_data(&block)
    ActiveRecord::Base.transaction do
      yield
      raise ActiveRecord::Rollback # ロールバックしてデータを残さない
    end
  end
  
  # テストごとのセットアップヘルパー
  def setup_basic_test_data
    {
      admin: create_admin,
      published_article: create_published_article,
      draft_article: create_draft_article
    }
  end
  
  private
  
  def adapter_supports_foreign_keys?
    ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
  end
end