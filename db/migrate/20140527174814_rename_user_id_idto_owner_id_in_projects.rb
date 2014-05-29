class RenameUserIdIdtoOwnerIdInProjects < ActiveRecord::Migration
  def change
    rename_column :projects, :user_id_id, :owner_id
  end
end
