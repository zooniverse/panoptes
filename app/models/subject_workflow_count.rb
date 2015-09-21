class SubjectWorkflowCount < ActiveRecord::Base
  # TODO Switch to false after old data has been backported and then remove altogether
  # Need to do multiple joins or conditions when this is active, might a little slower
  # so don't keep compat mode on for too long.
  BACKWARDS_COMPAT = true

  belongs_to :subject
  belongs_to :workflow

  scope :retired, -> { where.not(retired_at: nil) }

  if BACKWARDS_COMPAT
    # Cannot validate presence in this case (while we're migrating old data columns will be nillable)
    validates_uniqueness_of :set_member_subject_id, scope: :workflow_id
    validates_uniqueness_of :subject_id, scope: :workflow_id
  else
    validates :subject, presence: true, uniqueness: {scope: :workflow_id}
  end

  validates :workflow, presence: true

  def self.by_set(subject_set_id)
    if SubjectWorkflowCount::BACKWARDS_COMPAT
      joins("LEFT OUTER JOIN set_member_subjects sms1 ON subject_workflow_counts.set_member_subject_id = sms1.id")
        .joins("LEFT OUTER JOIN set_member_subjects sms2 ON subject_workflow_counts.subject_id = sms2.subject_id")
        .where("(sms1.id IS NOT NULL AND sms1.subject_set_id = ?) OR (sms2.id IS NOT NULL AND sms2.subject_set_id = ?)", subject_set_id, subject_set_id)
    else
      joins(:subject => :set_member_subjects).where(set_member_subjects: {subject_set_id: subject_set_id})
    end
  end

  def self.by_subject_workflow(subject_id, workflow_id)
    if SubjectWorkflowCount::BACKWARDS_COMPAT
      joins("LEFT OUTER JOIN set_member_subjects sms1 ON subject_workflow_counts.set_member_subject_id = sms1.id")
        .where("(sms1.id IS NOT NULL AND sms1.subject_id = ? AND subject_workflow_counts.workflow_id = ?) OR (subject_workflow_counts.subject_id = ? AND subject_workflow_counts.workflow_id = ?)", subject_id, workflow_id, subject_id, workflow_id)
        .first
    else
      where(subject_id: subject_id, workflow_id: workflow_id).first
    end
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
    if SubjectWorkflowCount::BACKWARDS_COMPAT
      ids = [set_member_subject_id]
      ids += subject.set_member_subjects.pluck(:id) if subject_id
      ids.flatten.compact
    else
      subject.set_member_subjects.pluck(:id)
    end
  end
end
