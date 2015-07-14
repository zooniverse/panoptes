class SubjectWorkflowCount < ActiveRecord::Base
  belongs_to :set_member_subject
  belongs_to :workflow

  validates_presence_of :set_member_subject, :workflow

  def retire?
    workflow.retirement_scheme.retire?(self)
  end

  def retire!
    SubjectLifecycle.new(set_member_subject.subject).retire_for(workflow)
  end
end
