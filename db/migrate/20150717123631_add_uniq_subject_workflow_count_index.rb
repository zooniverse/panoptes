class AddUniqSubjectWorkflowCountIndex < ActiveRecord::Migration
  def change
    add_index :subject_workflow_counts, [:set_member_subject_id, :workflow_id],
    unique: true, name: 'index_subject_workflow_counts_on_sms_id_and_workflow_id'
  end
end
