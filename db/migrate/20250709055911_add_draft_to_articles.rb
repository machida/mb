class AddDraftToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :draft, :boolean, default: false, null: false
  end
end
