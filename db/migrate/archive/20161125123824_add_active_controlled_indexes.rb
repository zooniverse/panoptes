class AddActiveControlledIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    #controlled public scopes
    add_index :projects, :private, algorithm: :concurrently
    add_index :collections, :private, algorithm: :concurrently

    # @active scope indexes
    add_index :subjects, :activated_state, algorithm: :concurrently
    add_index :collections, :activated_state, algorithm: :concurrently
    add_index :organizations, :activated_state, algorithm: :concurrently
    add_index :projects, :activated_state, algorithm: :concurrently
    add_index :user_groups, :activated_state, algorithm: :concurrently
    add_index :users, :activated_state, algorithm: :concurrently
    add_index :workflows, :activated_state, algorithm: :concurrently
  end
end
