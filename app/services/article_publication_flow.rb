class ArticlePublicationFlow
  include Rails.application.routes.url_helpers

  ACTIONS = {
    "下書き保存" => :draft,
    "公開" => :publish
  }.freeze

  DRAFT_NOTICE = "下書きを保存しました。".freeze
  PUBLISH_NOTICE = "記事を公開しました。".freeze

  def initialize(action_label)
    @action_label = action_label.to_s
  end

  def apply_state(article)
    case action
    when :draft
      article.draft = true
    when :publish
      article.draft = false
    end
  end

  def redirect_path(article)
    article.draft? ? admin_articles_path : article_path(article)
  end

  def notice_message(article)
    article.draft? ? DRAFT_NOTICE : PUBLISH_NOTICE
  end

  private

  attr_reader :action_label

  def action
    ACTIONS[action_label]
  end
end
