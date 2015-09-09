class SubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include BelongsToMany
  include WithOptimisticRetry

  DEFAULT_LENGTH = 100
  MINIMUM_LENGTH = 20

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
    queue = by_set(set_id).by_user_workflow(user, workflow)
    if queue.exists?
      enqueue_update(queue, sms_ids)
    else
      queue.create!(set_member_subject_ids: Array.wrap(sms_ids))
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
    enqueue_update(where(workflow: workflow), sms_ids)
  end

  def self.dequeue_for_all(workflow, sms_id)
    return if sms_id.blank?
    dequeue_update(where(workflow: workflow), sms_id)
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

  # NOTE: if the query scope returns a large set then
  # don't use this query outside of a background Worker
  # SQL optimisations welcome here...no postgres ops preseved order
  def self.dequeue_update(query, sms_ids)
    query.find_each { |sq| sq.dequeue(sms_ids) }
  end

  # NOTE: if the query scope returns a large set then
  # don't use this query outside of a background Worker
  # SQL optimisations welcome here...no postgres ops preseved order
  def self.enqueue_update(query, sms_ids)
    query.find_each { |sq| sq.enqueue(sms_ids) }
  end

  def self.below_minimum
    where("cardinality(set_member_subject_ids) < ?", MINIMUM_LENGTH)
  end

  def below_minimum?
    set_member_subject_ids.length < MINIMUM_LENGTH
  end

  def next_subjects(limit=10)
    if user_id
      non_retired_set_member_subject_ids[0..limit-1]
    else
      non_retired_set_member_subject_ids.sample(limit)
    end
  end

  def non_retired_set_member_subject_ids
    @non_retired_set_member_subject_ids ||= set_member_subject_ids - SubjectWorkflowCount.where(set_member_subject_id: set_member_subject_ids, workflow_id: workflow_id).where.not(retired_at: nil).pluck(:set_member_subject_id)
  end

  def dequeue(sms_ids)
    sms_ids = Array.wrap(sms_ids)
    with_optimistic_retry do
      dqd_non_dup_sms_ids = self.set_member_subject_ids - sms_ids
      self.set_member_subject_ids = dqd_non_dup_sms_ids
      self.save!
    end
  end

  def enqueue(sms_ids)
    sms_ids = Array.wrap(sms_ids)
    with_optimistic_retry do
      if self.below_minimum?
        enqueue_set = NonDuplicateSmsIds.new(self, sms_ids).enqueue_sms_ids_set
        if !enqueue_set.empty? && enqueue_set != self.set_member_subject_ids
          self.set_member_subject_ids = enqueue_set
          self.save!
        end
      end
    end
  end
end
