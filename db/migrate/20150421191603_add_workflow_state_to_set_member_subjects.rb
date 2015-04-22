class AddWorkflowStateToSetMemberSubjects < ActiveRecord::Migration
  def change
    add_column :set_member_subjects, :retired_workflow_ids, :integer, array: true, index: :gin
    SetMemberSubject.retired.find_each do |sms|
      sms.update(retired_workflows: sms.subject_set.workflows)
    end

    remove_column :set_member_subjects, :state
    remove_column :set_member_subjects, :classification_count
  end
end
