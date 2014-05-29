class CreateWorkflowSubjectGroupJoinTable < ActiveRecord::Migration
  def change
    create_join_table :subject_groups, :workflows do |t|
      # t.index [:subject_group_id, :workflow_id]
      # t.index [:workflow_id, :subject_group_id]
    end
  end
end
