class AddOauthTokensIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    Doorkeeper::AccessCleanup.new.cleanup!

    unless index_exists?(:oauth_access_tokens, [:application_id, :resource_owner_id])
      add_index :oauth_access_tokens, [:application_id, :resource_owner_id],
        name: 'index_oauth_access_tokens_on_app_id_and_owner_id',
        algorithm: :concurrently
    end
  end
end
