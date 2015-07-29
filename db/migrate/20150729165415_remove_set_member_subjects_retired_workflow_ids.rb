class RemoveSetMemberSubjectsRetiredWorkflowIds < ActiveRecord::Migration
  def change
    remove_column :set_member_subjects, :retired_workflow_ids, :integer, array: true, default: []
  end
end
