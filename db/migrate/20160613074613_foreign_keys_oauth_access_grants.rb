class ForeignKeysOauthAccessGrants < ActiveRecord::Migration
  def change
    add_foreign_key :oauth_access_grants, :users, column: :resource_owner_id, on_update: :cascade, on_delete: :cascade
    add_foreign_key :oauth_access_grants, :oauth_applications, column: :application_id, on_update: :cascade, on_delete: :cascade
  end
end
