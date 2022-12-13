class AddLowerIndexToEmail < ActiveRecord::Migration
  def change
    add_index :users, :email, name: "idx_lower_email", case_sensitive: false, unique: true
  end
end
