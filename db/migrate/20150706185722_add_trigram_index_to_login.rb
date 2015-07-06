class AddTrigramIndexToLogin < ActiveRecord::Migration
  def change
    remove_index :users, name: "users_display_name_trgm_index"
    add_index :users, name: "users_idx_trgm_login_display_name", using: :gin, operator_class: :gin_trgm_ops,
      expression: %((coalesce("users"."login"::text, '') || ' ' || coalesce("users"."display_name"::text, '')) gin_trgm_ops)
  end
end
