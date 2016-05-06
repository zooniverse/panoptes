class AddProjectState < ActiveRecord::Migration
  def change
    add_column :projects, :state, :integer
    add_index :projects, :state, where: "(state IS NOT NULL)", algorithm: :concurrently
  end
end
