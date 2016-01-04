class RemoveDeprecatedColumns < ActiveRecord::Migration
  def change
    remove_column :subject_workflow_counts, :set_member_subject_id
    remove_column :classifications, :subject_ids
  end
end
