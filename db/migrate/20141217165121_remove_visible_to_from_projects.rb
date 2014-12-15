class RemoveVisibleToFromProjects < ActiveRecord::Migration
  def change
    remove_column :projects, :visible_to, :string
  end
end
