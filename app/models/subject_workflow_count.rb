class SubjectWorkflowCount < ActiveRecord::Base
  include Linkable

  belongs_to :set_member_subject
  belongs_to :workflow

  scope :retired, -> { where.not(retired_at: nil) }

  validates_presence_of :set_member_subject, :workflow
  validates_uniqueness_of :set_member_subject_id, scope: :workflow_id

  def self.by_set(subject_set_id)
    joins(:set_member_subject).where(set_member_subjects: {subject_set_id: subject_set_id})
  end

  def self.by_subject_workflow(subject_id, workflow_id)
    joins(:set_member_subject).where(set_member_subjects: {subject_id: subject_id},
                                     workflow_id: workflow_id)
  end

  def retire?
    workflow.retirement_scheme.retire?(self)
  end

  def retire!
    return if retired?

    ActiveRecord::Base.transaction(requires_new: true) do
      touch(:retired_at)
      Workflow.increment_counter(:retired_set_member_subjects_count, workflow.id)
      yield if block_given?
    end
  end

  def retired?
    retired_at.present?
  end
end
