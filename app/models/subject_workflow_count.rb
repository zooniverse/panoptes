class SubjectWorkflowCount < ActiveRecord::Base
  belongs_to :set_member_subject
  belongs_to :workflow

  validates_presence_of :set_member_subject, :workflow

  def retire?
    workflow.retirement_scheme.retire?(self)
  end

  def retire!
    ActiveRecord::Base.transaction(requires_new: true) do
      set_member_subject.retire_workflow(workflow)
      Workflow.increment_counter(:retired_set_member_subjects_count, workflow.id)
      yield if block_given?
    end
  end
end
