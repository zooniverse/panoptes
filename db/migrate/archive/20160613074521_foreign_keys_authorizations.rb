class ForeignKeysAuthorizations < ActiveRecord::Migration
  def change
    add_foreign_key :authorizations, :users, on_update: :cascade, on_delete: :cascade
  end
end
