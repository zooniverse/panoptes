class AlterProjectsAddMobileFriendly < ActiveRecord::Migration
  def change
    add_column :projects, :mobile_friendly, :boolean, null: false, default: false, index: true
  end
end
