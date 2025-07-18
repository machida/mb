class Admin < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :user_id, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_blank: true

  has_many :articles, foreign_key: :author, primary_key: :user_id
end
