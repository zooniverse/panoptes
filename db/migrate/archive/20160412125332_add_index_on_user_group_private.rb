class AddIndexOnUserGroupPrivate < ActiveRecord::Migration
  disable_ddl_transaction!
  
  def change
    add_index :user_groups, :private, algorithm: :concurrently
  end
end
