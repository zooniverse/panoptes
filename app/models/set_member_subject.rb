require 'subjects/set_member_subject_selector'

class SetMemberSubject < ActiveRecord::Base

  belongs_to :subject_set
  belongs_to :subject
  has_many :workflows, through: :subject_set

  has_many :subject_workflow_statuses, through: :subject
  has_many :retired_subject_workflow_statuses,
    -> { retired },
    through: :subject,
    class_name: 'SubjectWorkflowStatus',
    source: 'subject_workflow_statuses'
  has_many :retired_workflows,
    through: :retired_subject_workflow_statuses,
    source: :workflow

  validates_presence_of :subject_set, :subject
  validates_uniqueness_of :subject_id, scope: :subject_set_id

  before_create :set_random

  def self.by_subject_workflow(subject_id, workflow_id)
    by_workflow(workflow_id).where(subject_id: subject_id)
  end

  def self.by_workflow(workflow_id)
    linked_workflow_set_ids = SubjectSetsWorkflow
      .where(workflow_id: workflow_id)
      .select(:subject_set_id)

    where(subject_set_id: linked_workflow_set_ids)
  end

  def self.non_retired_for_workflow(workflow_id)
    non_retired_subject_ids = SubjectWorkflowStatus
      .where(workflow_id: workflow_id)
      .where(retired_at: nil)
      .select(:subject_id)

    by_workflow(workflow_id).where(subject_id: non_retired_subject_ids)
  end

  def self.retired_for_workflow(workflow_id)
    retired_subject_ids = SubjectWorkflowStatus
      .where(workflow_id: workflow_id)
      .where.not(retired_at: nil)
      .select(:subject_id)

    by_workflow(workflow_id).where(subject_id: retired_subject_ids)
  end

  # Be careful using this query directly in the console
  # as it's not super selective on a large data set
  # and the LEFT JOIN can take a long time to resolve
  def self.unseen_for_user_by_workflow(user_id, workflow_id)
    uss = UserSeenSubject.arel_table
    seens = uss.project('UNNEST(subject_ids) as subject_id')
    user_seen_subject_ids = seens.where(uss[:user_id].eq(user_id).and(uss[:workflow_id].eq(workflow_id)))
    # use a CTE to unnest the seen subject ids for use in the join below
    # join the seen subject ids to the set member subjects
    # but only take the rows where the seen_for_user cte subject id is null
    # i.e. the one's we haven't seen yet
    # https://github.com/georgekaraszi/ActiveRecordExtended#common-table-expressions-cte
    unseen_smses =
      with(seen_for_user: user_seen_subject_ids)
      .joins('LEFT JOIN seen_for_user ON seen_for_user.subject_id = set_member_subjects.subject_id')
      .where(seen_for_user: { subject_id: nil })

    by_workflow(workflow_id).merge(unseen_smses)
  end

  def retired_workflow_ids
    retired_workflows.pluck(:id)
  end

  def retired_workflows=(workflows_to_retire)
    workflows_to_retire.each do |workflow|
      workflow.retire_subject(subject)
    end
  end

  def set_random
    self.random = rand
  end
end
