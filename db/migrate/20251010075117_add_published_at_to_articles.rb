class AddPublishedAtToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :published_at, :datetime

    # 既存の記事のpublished_atにcreated_atの値を設定
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE articles SET published_at = created_at WHERE published_at IS NULL
        SQL
      end
    end
  end
end
