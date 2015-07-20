class SetMemberSubject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include BelongsToMany
  include Linkable

  belongs_to :subject_set, counter_cache: true, touch: true
  belongs_to :subject
  has_many :subject_workflow_counts, dependent: :destroy
  has_many :workflows, through: :subject_set
  has_many :retired_subject_workflow_counts, -> { retired }, class_name: 'SubjectWorkflowCount'
  has_many :retired_workflows, through: :retired_subject_workflow_counts, source: :workflow

  validates_presence_of :subject_set, :subject
  validates_uniqueness_of :subject_id, scope: :subject_set_id

  can_through_parent :subject_set, :update, :show, :destroy, :index, :update_links,
    :destroy_links

  before_save :timestamp_newly_retired_workflows
  before_create :set_random
  before_destroy :remove_from_queues

  can_be_linked :subject_queue, :in_workflow, :model

  def self.in_workflow(queue)
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

  def retire_workflow(workflow)
    count = subject_workflow_counts.find_or_create_by!(workflow_id: workflow.id)
    count.retire!
  end

  def retired_workflow_ids
    retired_workflows.pluck(:id)
  end

  def retired_workflow_ids=(val)
    raise 'Deprecated'
  end

  def remove_from_queues
    QueueRemovalWorker.perform_async(id, subject_set.workflows.pluck(:id))
  end

  def set_random
    self.random = rand
  end

  def timestamp_newly_retired_workflows
    retired_subject_workflow_counts.each do |record|
      # Make sure that any subject workflow count added
      record.retired_at ||= Time.now
      record.save if record.persisted? and record.changed?
    end
  end
end
