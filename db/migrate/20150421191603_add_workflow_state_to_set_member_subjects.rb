class AddWorkflowStateToSetMemberSubjects < ActiveRecord::Migration
  def change
    add_column :set_member_subjects, :retired_workflow_ids, :integer, array: true, index: :gin, default: []

    SetMemberSubject.where(state: 2).find_each do |sms|
      sms.update(retired_workflows: sms.subject_set.workflows)
    end

    remove_column :set_member_subjects, :state
  end
end
