xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title SiteSetting.site_title
    xml.description SiteSetting.top_page_description
    xml.link root_url
    xml.language "ja"
    xml.lastBuildDate @articles.first&.updated_at&.rfc822
    xml.tag! "atom:link", href: feed_url, rel: "self", type: "application/rss+xml"

    @articles.each do |article|
      xml.item do
        xml.title article.title
        xml.description article.summary.present? ? article.summary : truncate(strip_tags(markdown(article.body)), length: 300)
        xml.link article_url(article)
        xml.guid article_url(article), isPermaLink: "true"
        xml.pubDate article.created_at.rfc822
        xml.author "#{SiteSetting.site_title}"

        # 記事にサムネイル画像がある場合は画像も含める
        if article.thumbnail.present?
          image_url = article.thumbnail.start_with?("http") ? article.thumbnail : "#{request.protocol}#{request.host_with_port}#{article.thumbnail}"
          xml.enclosure url: image_url, type: "image/jpeg"
        end
      end
    end
  end
end
