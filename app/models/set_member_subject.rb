class SetMemberSubject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable
  include Counter::Cache

  belongs_to :subject_set, touch: true
  belongs_to :subject
  has_many :subject_workflow_counts, dependent: :destroy
  has_many :workflows, through: :subject_set
  has_many :retired_subject_workflow_counts, -> { retired }, class_name: 'SubjectWorkflowCount'
  has_many :retired_workflows, through: :retired_subject_workflow_counts, source: :workflow

  validates_presence_of :subject_set, :subject
  validates_uniqueness_of :subject_id, scope: :subject_set_id

  can_through_parent :subject_set, :update, :show, :destroy, :index, :update_links,
    :destroy_links

  before_create :set_random
  before_destroy :remove_from_queues

  can_be_linked :subject_queue, :in_queue_workflow, :model

  counter_cache_on column: :set_member_subjects_count, relation: :subject_set,
    method: :set_member_subject_count, relation_class_name: "SubjectSet"

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
    by_workflow(workflow)
    .joins("LEFT OUTER JOIN subject_workflow_counts ON subject_workflow_counts.set_member_subject_id = set_member_subjects.id")
    .where('subject_workflow_counts.id IS NULL OR subject_workflow_counts.retired_at IS NULL')
  end

  def self.unseen_for_user_by_workflow(user, workflow)
    by_workflow(workflow)
    .joins("LEFT OUTER JOIN user_seen_subjects ON user_seen_subjects.user_id = #{user.id} AND user_seen_subjects.workflow_id = #{workflow.id}")
    .where('user_seen_subjects.id IS NULL OR (NOT "set_member_subjects"."subject_id" = ANY("user_seen_subjects"."subject_ids"))')
  end

  def retire_workflow(workflow)
    count = subject_workflow_counts.find_or_create_by!(workflow_id: workflow.id)
    count.retire!
  end

  def retired_workflow_ids
    retired_workflows.pluck(:id)
  end

  def retire_associated_subject_workflow_counts
    retired_subject_workflow_counts.each(&:retire!)
    subject_workflow_counts.reset
    workflows.reset
  end

  def remove_from_queues
    QueueRemovalWorker.perform_async(id, subject_set.workflows.pluck(:id))
  end

  def set_random
    self.random = rand
  end
end
