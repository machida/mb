class AddPasswordChangedAtToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :password_changed_at, :datetime
  end
end
