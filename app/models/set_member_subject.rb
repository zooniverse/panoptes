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
    query = joins(:subject_set)
      .where(subject_sets: { workflow_id: queue.workflow.id })
    query = query.where(subject_set_id: queue.subject_set.id) if queue.subject_set
    query
  end

  def self.by_subject_workflow(subject_id, workflow_id)
    joins(subject_set: :workflows)
      .where(subject_id: subject_id, workflows: {id: workflow_id })
  end

  def self.available(workflow, user)
    fields = '"set_member_subjects"."subject_id", "set_member_subjects"."random"'
    if select_from_all?(workflow, user)
      workflow.set_member_subjects.select(fields)
    else
      select(fields)
        .joins(subject_set: {workflows: :user_seen_subjects})
        .where(user_seen_subjects: {user_id: user.id},
               workflows: {id: workflow.id})
        .where.not('? = ANY("set_member_subjects"."retired_workflow_ids")', workflow.id)
        .where.not('"set_member_subjects"."subject_id" = ANY("user_seen_subjects"."subject_ids")')
    end
  end

  def self.select_from_all?(workflow, user)
    !user ||
      !user.user_seen_subjects.where(workflow: workflow).exists? ||
      workflow.finished? ||
      user.has_finished?(workflow)
  end

  def retire_workflow(workflow)
    retired_workflows << workflow
    save!
  end

  def set_random
    self.random = rand
  end
end
