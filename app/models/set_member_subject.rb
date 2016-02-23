require 'subjects/set_member_subject_selector'

class SetMemberSubject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable

  belongs_to :subject_set
  belongs_to :subject
  has_many :workflows, through: :subject_set

  has_many :subject_workflow_counts, through: :subject
  has_many :retired_subject_workflow_counts, -> { retired }, through: :subject, class_name: 'SubjectWorkflowCount', source: 'subject_workflow_counts'
  has_many :retired_workflows, through: :retired_subject_workflow_counts, source: :workflow

  validates_presence_of :subject_set, :subject
  validates_uniqueness_of :subject_id, scope: :subject_set_id

  can_through_parent :subject_set, :update, :show, :destroy, :index, :update_links,
    :destroy_links

  before_create :set_random

  can_be_linked :subject_queue, :in_queue_workflow, :model

  after_create :update_counter
  before_destroy :update_counter

  def self.in_queue_workflow(queue)
    query = joins(subject_set: :workflows)
      .where(workflows: { id: queue.workflow.id })
    query = query.where(subject_set_id: queue.subject_set.id) if queue.subject_set
    query
  end

  def self.by_subject_workflow(subject_id, workflow_id)
    joins(subject_set: :workflows)
      .where(subject_id: subject_id, workflows: {id: workflow_id })
  end

  def self.available(workflow, user)
    Subjects::SetMemberSubjectSelector.new(workflow, user).set_member_subjects
  end

  def self.by_workflow(workflow)
    joins(:workflows).where(workflows: {id: workflow.id})
  end

  def self.non_retired_for_workflow(workflow)
    by_workflow(workflow)
    .joins(sanitize_sql_for_conditions(["LEFT OUTER JOIN subject_workflow_counts ON subject_workflow_counts.subject_id = set_member_subjects.subject_id AND subject_workflow_counts.workflow_id = ?", workflow.id]))
    .where('subject_workflow_counts.retired_at IS NULL')
  end

  def self.unseen_for_user_by_workflow(user, workflow)
    uss = UserSeenSubject.arel_table
    sms = SetMemberSubject.arel_table
    seens = uss.project('UNNEST(subject_ids) as subject_id')
    seens.where(uss[:user_id].eq(user.id).and(uss[:workflow_id].eq(workflow.id)))
    seens_subquery = seens.as(Arel.sql('as seen_subjects'))
    manager = Arel::SelectManager.new(uss.engine)
    manager.project("null")
    manager.from(seens_subquery)
    subquery_where = sms[:subject_id].eq(Arel.sql('seen_subjects.subject_id'))
    seen_subjects = manager.where(subquery_where)
    by_workflow(workflow).where(seen_subjects.exists.not)
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

  def update_counter
    SubjectSetSubjectCounterWorker.perform_in(3.minutes, subject_set_id)
  end
end
