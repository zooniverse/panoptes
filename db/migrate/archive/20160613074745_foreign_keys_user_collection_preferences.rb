class ForeignKeysUserCollectionPreferences < ActiveRecord::Migration
  def change
    add_foreign_key :user_collection_preferences, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :user_collection_preferences, :collections, on_update: :cascade, on_delete: :cascade
  end
end
