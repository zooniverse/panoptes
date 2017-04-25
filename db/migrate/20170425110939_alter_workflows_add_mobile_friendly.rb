class AlterWorkflowsAddMobileFriendly < ActiveRecord::Migration
  def change
    add_column :workflows, :mobile_friendly, :boolean, null: false, default: false, index: true
  end
end
