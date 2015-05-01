class SubjectWorkflowCount < ActiveRecord::Base
  belongs_to :set_member_subject
  belongs_to :workflow

  validates_presence_of :set_member_subject, :workflow

  def retire?
    workflow.retirement_scheme.retire?(self)
  end

  def retire!
    ActiveRecord::Base.transaction(requires_new: true) do
      SetMemberSubject
        .where(id: set_member_subject.id)
        .update_all(["retired_workflow_ids = array_append(retired_workflow_ids, ?)", workflow.id])
      Workflow.increment_counter(:retired_set_member_subjects_count, workflow.id)
      yield if block_given?
    end
  end
end
