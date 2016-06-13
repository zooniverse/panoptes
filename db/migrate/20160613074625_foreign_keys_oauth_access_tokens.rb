class ForeignKeysOauthAccessTokens < ActiveRecord::Migration
  def change
    Doorkeeper::AccessToken.joins("LEFT OUTER JOIN users ON users.id = oauth_access_tokens.resource_owner_id").where("oauth_access_tokens.resource_owner_id IS NOT NULL AND users.id IS NULL").delete_all
    add_foreign_key :oauth_access_tokens, :users, column: :resource_owner_id, on_update: :cascade, on_delete: :cascade
    add_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id, on_update: :cascade, on_delete: :cascade
  end
end
