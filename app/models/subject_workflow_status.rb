class SubjectWorkflowStatus < ActiveRecord::Base
  self.table_name = 'subject_workflow_counts'


  belongs_to :subject
  belongs_to :workflow

  enum retirement_reason:
    [ :classification_count, :flagged, :nothing_here, :consensus, :other, :human ]

  scope :retired, -> { where.not(retired_at: nil) }

  validates :subject, presence: true, uniqueness: {scope: :workflow_id}
  validates :workflow, presence: true

  delegate :set_member_subjects, to: :subject
  delegate :project, to: :workflow

  def self.by_subject(subject_id)
    where(subject_id: subject_id)
  end

  def self.by_workflow(workflow_id)
    where(workflow_id: workflow_id)
  end

  def self.by_subject_workflow(subject_id, workflow_id)
    where(subject_id: subject_id, workflow_id: workflow_id).first
  end

  def retire?
    return false if retired?
    Workflow
    .select(:retirement)
    .find(workflow_id)
    .retirement_scheme.retire?(self)
  end

  def retire!(reason=nil)
    unless retired?
      update!(retirement_reason: reason, retired_at: Time.zone.now)
    end
  end

  def retired?
    retired_at.present?
  end

  def set_member_subject_ids
    set_member_subjects.pluck(:id)
  end
end
