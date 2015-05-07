class AddValidEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :valid_email, :boolean, default: true, null: false
  end
end
