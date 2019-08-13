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

  # Be careful using this query as it's not selective on a large table
  # and the LEFT OUTER JOIN can take a long time to resolve
  def self.unseen_for_user_by_workflow(user_id, workflow_id)
    all_sms = all_sms_for_user_by_workflow(user_id, workflow_id)
    unseen_smses = all_sms.where("seen_subject_ids.subject_id IS NULL")

    by_workflow(workflow_id).merge(unseen_smses)
  end

  def self.all_sms_for_user_by_workflow(user_id, workflow_id)
    uss = UserSeenSubject.arel_table
    seens = uss.project('UNNEST(subject_ids) as subject_id')
    seens.where(uss[:user_id].eq(user_id).and(uss[:workflow_id].eq(workflow_id)))
    seens_subquery = seens.as(Arel.sql('as seen_subject_ids'))
    joins(
      "LEFT OUTER JOIN #{seens_subquery.to_sql} " \
      "ON set_member_subjects.subject_id = seen_subject_ids.subject_id"
    )
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

  def adjacent(window=5, gap=1)
    upper = priority + (window*gap)
    lower = priority - (window*gap)

    range_smses = SetMemberSubject
      .where(subject_set_id: subject_set_id)
      .where("priority >= ? AND priority <= ?", lower, upper)
      .order(:priority)
    this_index = range_smses.find_index(self)

    indexes = [this_index]
    x = y = this_index
    window.times do
      indexes.push(x + gap)
      indexes.unshift(y - gap)

      x = (x + gap)
      y = (y - gap)
    end

    new_smses = indexes.map{|i| i.negative? ? nil : range_smses[i]}
  end
end
