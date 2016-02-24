class SubjectWorkflowCount < ActiveRecord::Base
  belongs_to :subject
  belongs_to :workflow

  scope :retired, -> { where.not(retired_at: nil) }

  validates :subject, presence: true, uniqueness: {scope: :workflow_id}
  validates :workflow, presence: true

  delegate :set_member_subjects, to: :subject

  def self.by_set(subject_set_id)
    joins(:subject => :set_member_subjects).where(set_member_subjects: {subject_set_id: subject_set_id})
  end

  def self.by_subject(subject_id)
    where(subject_id: subject_id)
  end

  def self.by_subject_workflow(subject_id, workflow_id)
    where(subject_id: subject_id, workflow_id: workflow_id).first
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

  def set_member_subject_ids
    set_member_subjects.pluck(:id)
  end
end
