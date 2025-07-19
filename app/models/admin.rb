class Admin < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
  validates :user_id, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_blank: true

  has_many :articles, foreign_key: :author, primary_key: :user_id

  # 初回ログイン後のパスワード変更が必要かどうか
  def needs_password_change?
    password_changed_at.blank?
  end

  # 最後の管理者かどうか
  def last_admin?
    Admin.count == 1
  end

  # 管理者削除時の記事移譲処理
  def transfer_articles_to(target_admin)
    return false if target_admin.blank?
    
    articles.update_all(author: target_admin.user_id)
    true
  end

  # 管理者削除時の記事削除処理
  def delete_articles
    articles.destroy_all
  end
end
