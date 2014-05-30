class AddOwnerTypeToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :owner_type, :string
  end
end
