class ArticleNavigationComponent < ViewComponent::Base
  def initialize
  end

  private

  def nav_items
    [
      {
        text: "全ての記事",
        path: admin_articles_path,
        active: current_page?(admin_articles_path)
      },
      {
        text: "下書き記事", 
        path: drafts_admin_articles_path,
        active: current_page?(drafts_admin_articles_path)
      }
    ]
  end

  def nav_class_for(item)
    "a--button is-md #{item[:active] ? 'is-warning' : 'is-border-secondary'}"
  end
end