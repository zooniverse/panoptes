class ForeignKeysAccessControlLists < ActiveRecord::Migration
  def change
    add_foreign_key :access_control_lists, :user_groups, on_update: :cascade, on_delete: :cascade
  end
end
