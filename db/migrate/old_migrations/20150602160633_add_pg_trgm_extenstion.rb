class AddPgTrgmExtenstion < ActiveRecord::Migration
  def change
    enable_extension "pg_trgm"
    add_index :users, :display_name, operator_class: :gist_trgm_ops, using: :gist,
      name: 'users_display_name_trgm_index'
  end
end
