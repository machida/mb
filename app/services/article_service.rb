class ArticleService
  attr_reader :article

  def initialize(article)
    @article = article
  end

  def og_image_url
    if article.thumbnail.present?
      # アップロード時に既にOGサイズにリサイズされているので、サムネイル画像をそのまま使用
      article.thumbnail
    elsif SiteSetting.default_og_image.present?
      # デフォルトOG画像も既にOGサイズにリサイズされているので、そのまま使用
      SiteSetting.default_og_image
    end
  end

  def formatted_body
    return "" if article.body.blank?
    
    # マークダウン処理をここで実行
    # 今後マークダウンライブラリを使用する場合はここで処理
    article.body
  end

  def summary_for_display
    return article.summary if article.summary.present?
    
    # 本文から自動生成する場合のロジック
    truncated_body = article.body&.gsub(/^#+ /, "")&.strip
    truncated_body&.truncate(150)
  end

  def publish!
    article.update!(draft: false)
  end

  def unpublish!
    article.update!(draft: true)
  end

  def self.create_article(params, author)
    article = Article.new(params)
    article.author = author
    article.save ? article : nil
  end
end