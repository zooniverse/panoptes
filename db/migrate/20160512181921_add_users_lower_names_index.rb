class AddUsersLowerNamesIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :users, [:login, :display_name],
      case_sensitive: false,
      operator_class: 'text_pattern_ops',
      name: 'index_users_on_lower_names',
      algorithm: :concurrently
  end
end
