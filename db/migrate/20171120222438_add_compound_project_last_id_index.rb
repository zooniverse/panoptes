class AddCompoundProjectLastIdIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :classifications, %i(project_id id), algorithm: :concurrently
    remove_index :classifications, column: :project_id
  end
end
