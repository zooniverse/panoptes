class ForeignKeysMemberships < ActiveRecord::Migration
  def change
    Membership.joins("LEFT OUTER JOIN users ON users.id = memberships.user_id").where("memberships.user_id IS NOT NULL AND users.id IS NULL").delete_all
    add_foreign_key :memberships, :user_groups, on_update: :cascade, on_delete: :cascade
    add_foreign_key :memberships, :users, on_update: :cascade, on_delete: :cascade
  end
end
