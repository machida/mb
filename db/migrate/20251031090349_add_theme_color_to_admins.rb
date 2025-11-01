class AddThemeColorToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :theme_color, :string, default: "sky", null: false
  end
end
