class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :body
      t.text :summary
      t.string :thumbnail
      t.string :author

      t.timestamps
    end
  end
end
