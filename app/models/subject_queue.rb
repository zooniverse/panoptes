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

  def self.by_set(set_id)
    set_id ? where(subject_set_id: set_id) : all
  end

  def self.by_user_workflow(user, workflow)
    where(user: user, workflow: workflow)
  end

  def self.scope_for(action, groups, opts={})
    case action
    when :show, :index
      where(workflow: Workflow.scope_for(:update, groups, opts))
    else
      super
    end
  end

  def self.reload(workflow, sms_ids, user: nil, set_id: nil)
    queue = by_set(set_id).by_user_workflow(user, workflow)
    if queue.exists?
      queue.update_all(set_member_subject_ids: Array.wrap(sms_ids))
    else
      queue.create!(set_member_subject_ids: Array.wrap(sms_ids))
    end
  end

  def self.enqueue(workflow, sms_ids, user: nil, set_id: nil)
    return if sms_ids.blank?
    sms_ids = Array.wrap(sms_ids)
    unseen_ids = SeenSubjectRemover.new(user, workflow, sms_ids).ids_to_enqueue
    queue_context = by_set(set_id).by_user_workflow(user, workflow)
    if queue = queue_context.first
      queue.enqueue_update(unseen_ids)
    else
      queue_context.create!(set_member_subject_ids: unseen_ids)
    end
  end

  def self.dequeue(workflow, sms_ids, user: nil, set_id: nil)
    return if sms_ids.blank?
    queue = by_set(set_id).by_user_workflow(user, workflow)
    dequeue_update(queue, sms_ids)
  end

  def self.enqueue_for_all(workflow, sms_ids)
    return if sms_ids.blank?
    sms_ids = Array.wrap(sms_ids)
    where(workflow: workflow).each do |queue|
      queue.enqueue_update(sms_ids)
    end
  end

  def self.dequeue_for_all(workflow, sms_ids)
    return if sms_ids.blank?
    sms_ids = Array.wrap(sms_ids)
    dequeue_update(where(workflow: workflow), sms_ids)
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

  def self.below_minimum
    where("cardinality(set_member_subject_ids) < ?", MINIMUM_LENGTH)
  end

  def below_minimum?
    set_member_subject_ids.length < MINIMUM_LENGTH
  end

  def next_subjects(limit=10)
    if workflow.prioritized
      set_member_subject_ids[0..limit-1]
    else
      set_member_subject_ids.sample(limit)
    end
  end

  def enqueue_update(sms_ids)
    return if sms_ids.blank?
    update_queue_ids(set_member_subject_ids | sms_ids)
  end

  def dequeue_update(sms_ids)
    return if sms_ids.blank?
    diff_ids = (set_member_subject_ids - sms_ids)
    update_queue_ids(diff_ids)
  end

  private

  def update_queue_ids(sms_ids)
    capped_sms_ids = cap_queue_length(sms_ids)
    self.update_attribute(:set_member_subject_ids, capped_sms_ids)
  end

  def cap_queue_length(sms_ids)
    sms_ids.slice(0, DEFAULT_LENGTH)
  end
end
