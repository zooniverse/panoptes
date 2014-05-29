class RenameSubjectGroupsToSubjectSets < ActiveRecord::Migration
  def change
    rename_table :subject_groups, :subject_sets
    rename_table :subject_groups_workflows, :subject_sets_workflows
    rename_column :subject_sets_workflows, :subject_group_id, :subject_set_id
  end
end
