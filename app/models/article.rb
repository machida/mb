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
  
  def og_image_url
    if thumbnail.present?
      # アップロード時に既にOGサイズにリサイズされているので、サムネイル画像をそのまま使用
      thumbnail
    elsif SiteSetting.default_og_image.present?
      # デフォルトOG画像も既にOGサイズにリサイズされているので、そのまま使用
      SiteSetting.default_og_image
    end
  end
  
end
