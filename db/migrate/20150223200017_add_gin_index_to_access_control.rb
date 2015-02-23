class AddGinIndexToAccessControl < ActiveRecord::Migration
  def change
    add_index :access_control_lists, :roles, using: :gin
  end
end
