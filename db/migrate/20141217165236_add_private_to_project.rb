class AddPrivateToProject < ActiveRecord::Migration
  def change
    add_column :projects, :private, :boolean
  end
end
