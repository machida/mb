class AddPasswordResetToAdmins < ActiveRecord::Migration[8.0]
  def change
    add_column :admins, :password_reset_token, :string
    add_column :admins, :password_reset_sent_at, :datetime
    add_index :admins, :password_reset_token, unique: true
  end
end
