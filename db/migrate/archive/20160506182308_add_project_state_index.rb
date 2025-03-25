class AddProjectStateIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :projects,
    :state,
    where: "(state IS NOT NULL)",
    algorithm: :concurrently
  end
end
