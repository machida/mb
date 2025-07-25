class Article < ApplicationRecord
  belongs_to :admin, foreign_key: :author, primary_key: :user_id, optional: true

  validates :title, presence: true
  validates :body, presence: true
  validates :author, presence: true

  scope :published, -> { where(draft: false) }
  scope :drafts, -> { where(draft: true) }


  def published?
    !draft
  end

  def draft?
    draft
  end

  def service
    @service ||= ArticleService.new(self)
  end

  def og_image_url
    service.og_image_url
  end
end
