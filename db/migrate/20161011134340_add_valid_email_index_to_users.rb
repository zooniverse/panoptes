class AddValidEmailIndexToUsers < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :users, :valid_email, algorithm: :concurrently
  end
end
