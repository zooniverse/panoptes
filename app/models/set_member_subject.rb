class SetMemberSubject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable
  
  belongs_to :subject_set, counter_cache: true, touch: true
  belongs_to :subject

  enum state: [:active, :inactive, :retired]

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

  def self.by_subject_workflow(subject, workflow)
    joins(:subject_set)
      .where(subject_id: subject, subject_sets: { workflow_id: workflow })
  end

  def self.available(workflow, user)
    fields = '"set_member_subjects"."subject_id", "set_member_subjects"."random"'
    if !user || workflow.finished? || user.has_finished?(workflow)
      select(fields)
        .joins(subject_set: :workflow )
        .where(subject_sets: { workflow_id: workflow.id })
    else
      select(fields)
        .joins(subject_set: { workflow: :user_seen_subjects })
        .where(subject_sets: { workflow_id: workflow.id })
        .where(user_seen_subjects: { user_id: user.id })
        .where(state: states[:active])
        .where.not('"set_member_subjects"."subject_id" = ANY("user_seen_subjects"."subject_ids")')
    end
  end
  
  def retire?
    subject_set.retire_member?(self)
  end

  def set_random
    self.random = rand
  end
end
