class RebuildOauthTokenIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    remove_index :oauth_access_tokens, column: :token, unique: true
    add_index :oauth_access_tokens, :token, unique: true, algorithm: :concurrently
  end
end
