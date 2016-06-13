class ForeignKeysUsers < ActiveRecord::Migration
  def change
    add_foreign_key :users, :projects, on_update: :cascade, on_delete: :restrict
  end
end
