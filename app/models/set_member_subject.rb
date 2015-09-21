class SetMemberSubject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable

  belongs_to :subject_set, counter_cache: true, touch: true
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
  before_destroy :remove_from_queues

  can_be_linked :subject_queue, :in_queue_workflow, :model

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
    SetMemberSubjectSelector.new(workflow, user).set_member_subjects
  end

  def self.by_workflow(workflow)
    joins(:workflows).where(workflows: {id: workflow.id})
  end

  def self.non_retired_for_workflow(workflow)
    if SubjectWorkflowCount::BACKWARDS_COMPAT
      by_workflow(workflow)
        .joins("LEFT OUTER JOIN subject_workflow_counts swc1 ON swc1.set_member_subject_id = set_member_subjects.id")
        .joins("LEFT OUTER JOIN subject_workflow_counts swc2 ON swc2.subject_id = set_member_subjects.subject_id")
        .where('swc1.id IS NULL OR swc1.retired_at IS NULL')
        .where('swc2.id IS NULL OR swc2.retired_at IS NULL')
    else
      by_workflow(workflow)
      .joins("LEFT OUTER JOIN subject_workflow_counts ON subject_workflow_counts.subject_id = set_member_subjects.subject_id")
      .where('subject_workflow_counts.id IS NULL OR subject_workflow_counts.retired_at IS NULL')
    end
  end

  def self.unseen_for_user_by_workflow(user, workflow)
    by_workflow(workflow)
    .joins("LEFT OUTER JOIN user_seen_subjects ON user_seen_subjects.user_id = #{user.id} AND user_seen_subjects.workflow_id = #{workflow.id}")
    .where('user_seen_subjects.id IS NULL OR (NOT "set_member_subjects"."subject_id" = ANY("user_seen_subjects"."subject_ids"))')
  end

  def retired_workflow_ids
    retired_workflows.pluck(:id)
  end

  def retired_workflows
    if SubjectWorkflowCount::BACKWARDS_COMPAT
      workflow_ids = SubjectWorkflowCount.retired.by_subject(subject_id).pluck(:workflow_id)
      Workflow.where(id: workflow_ids)
    else
      super
    end
  end

  def retired_workflows=(workflows_to_retire)
    workflows_to_retire.each do |workflow|
      workflow.retire_subject(subject)
    end
  end

  def remove_from_queues
    QueueRemovalWorker.perform_async(id, subject_set.workflows.pluck(:id))
  end

  def set_random
    self.random = rand
  end
end
