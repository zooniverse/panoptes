require 'seen_subject_remover'

class SubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include BelongsToMany

  DEFAULT_LENGTH = 20
  MINIMUM_LENGTH = 10

  belongs_to :user
  belongs_to :workflow
  belongs_to :subject_set
  belongs_to_many :set_member_subjects

  validates_presence_of :workflow
  validates_uniqueness_of :user_id, scope: [:subject_set_id, :workflow_id]

  can_through_parent :workflow, :update, :destroy, :update_links, :destroy_links

  alias_method :subjects=, :set_member_subjects=

  def self.scope_for(action, groups, opts={})
    case action
    when :show, :index
      where(workflow: Workflow.scope_for(:update, groups, opts))
    else
      super
    end
  end

  def self.by_set(set_id)
    set_id ? where(subject_set_id: set_id) : all
  end

  def self.create_for_user(workflow, user, set_id: nil)
    if logged_out_queue = by_set(set_id).find_by(workflow: workflow, user: nil)
      queue = create(workflow: workflow,
                     user: user,
                     subject_set_id: set_id,
                     set_member_subject_ids: logged_out_queue.set_member_subject_ids)
      queue if queue.persisted?
    else
      EnqueueSubjectQueueWorker.perform_async(workflow.id, nil, set_id)
      nil
    end
  end

  def below_minimum?
    set_member_subject_ids.length < MINIMUM_LENGTH
  end

  def next_subjects(limit=10)
    sms_ids = if workflow.prioritized
      set_member_subject_ids[0..limit-1]
    else
      set_member_subject_ids.sample(limit)
    end
    dequeue_update(sms_ids)
    sms_ids
  end

  def enqueue_update(sms_ids)
    return if sms_ids.blank?
    update_queue_ids(set_member_subject_ids | Array.wrap(sms_ids))
  end

  def dequeue_update(sms_ids)
    return if sms_ids.blank?
    diff_ids = (set_member_subject_ids - Array.wrap(sms_ids))
    update_queue_ids(diff_ids)
  end

  private

  def update_queue_ids(sms_ids)
    capped_sms_ids = cap_queue_length(sms_ids)
    update_attribute(:set_member_subject_ids, capped_sms_ids)
  end

  def cap_queue_length(sms_ids)
    sms_ids.slice(0, DEFAULT_LENGTH)
  end
end
