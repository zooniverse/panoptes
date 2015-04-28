class SetMemberSubject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include BelongsToMany
  include Linkable

  belongs_to :subject_set, counter_cache: true, touch: true
  belongs_to :subject
  belongs_to_many :retired_workflows, class_name: "Workflow"
  has_many :subject_workflow_counts, dependent: :destroy

  validates_presence_of :subject_set, :subject

  can_through_parent :subject_set, :update, :show, :destroy, :index, :update_links,
    :destroy_links

  before_create :set_random

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
    retired_workflows << workflow
    save!
  end

  def set_random
    self.random = rand
  end
end
