class SubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include BelongsToMany

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

  def self.by_set(set)
    set ? where(subject_set_id: set) : all
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

  def self.reload(workflow, sms_ids, user: nil, set: nil)
    queue = by_set(set).by_user_workflow(user, workflow)
    if queue.exists?
      queue.update_all(set_member_subject_ids: Array.wrap(sms_ids))
    else
      queue.create!(set_member_subject_ids: Array.wrap(sms_ids))
    end
  end

  def self.enqueue(workflow, sms_ids, user: nil, set: nil)
    return if sms_ids.blank?
    queue = by_set(set).by_user_workflow(user, workflow)
    if queue.exists?
      enqueue_update(queue, sms_ids)
    else
      queue.create!(set_member_subject_ids: Array.wrap(sms_ids))
    end
  end

  def self.dequeue(workflow, sms_ids, user: nil, set: nil)
    return if sms_ids.blank?
    queue = by_set(set).by_user_workflow(user, workflow)
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

  def self.create_for_user(workflow, user, set: nil)
    if logged_out_queue = by_set(set).find_by(workflow: workflow, user: nil)
      queue = create(workflow: workflow,
                     user: user,
                     subject_set_id: set,
                     set_member_subject_ids: logged_out_queue.set_member_subject_ids)
      queue if queue.persisted?
    else
      EnqueueSubjectQueueWorker.perform_async(workflow.id, nil)
      nil
    end
  end

  # NOTE: if the query scope returns a large set then
  # don't use this query outside of a background Worker
  # SQL optimisations welcome here...no postgres ops preseved order
  def self.dequeue_update(query, sms_ids)
    query.find_each do |sq|
      dqd_non_dup_sms_ids = sq.set_member_subject_ids - Array.wrap(sms_ids)
      sq.update_column(:set_member_subject_ids, dqd_non_dup_sms_ids)
    end
  end

  # NOTE: if the query scope returns a large set then
  # don't use this query outside of a background Worker
  # SQL optimisations welcome here...no postgres ops preseved order
  def self.enqueue_update(query, sms_ids)
    query.find_each do |sq|
      sms_ids = Array.wrap(sms_ids)
      enqd_non_dup_sms_ids = sq.set_member_subject_ids | sms_ids
      notify_dup_subject_queue_error(
        enq_size: enqd_non_dup_sms_ids.length,
        curr_size: sq.set_member_subject_ids.size,
        append_size: sms_ids.length
      )
      enqueue_set = enqueue_sms_ids(sq, enqd_non_dup_sms_ids)
      sq.update_column(:set_member_subject_ids, enqueue_set)
    end
  end

  def self.below_minimum
    where("cardinality(set_member_subject_ids) < ?", MINIMUM_LENGTH)
  end

  def below_minimum?
    set_member_subject_ids.length < MINIMUM_LENGTH
  end

  def next_subjects(limit=10)
    if user_id
      set_member_subject_ids[0..limit-1]
    else
      set_member_subject_ids.sample(limit)
    end
  end

  private

  #NOTE: this can be removed when we're happy that
  # https://github.com/zooniverse/Panoptes/issues/1069
  # is resolved.
  def self.notify_dup_subject_queue_error(enq_size:, curr_size:, append_size:)
    params = { enq_size: enq_size, curr_size: curr_size, append_size: append_size }
    if enq_size != curr_size + append_size
      Honeybadger.notify(
        error_class:   "Subject Queue Duplicates",
        error_message: "Appending duplicates to subject queue",
        parameters:  params
      )
    end
    if enq_size > (DEFAULT_LENGTH * 2)
      Honeybadger.notify(
        error_class:   "Subject Queue Unbound Growth",
        error_message: "Queue is growing too large",
        parameters:  params
      )
    end
  end

  #NOTE: this can be removed when we're happy that
  # https://github.com/zooniverse/Panoptes/issues/1069
  # is resolved.
  def self.notify_dup_subject_seen_before_error(queue, seen_before_set)
    params = {
      user_id: queue.user.id,
      workflow_id: queue.workflow.id,
      seen_before_sms_ids: seen_before_set.map(&:id),
      seen_before_subject_ids: seen_before_set.map(&:subject_id)
    }
    Honeybadger.notify(
      error_class:   "Subject Queue Seen Before",
      error_message: "Appending seen before subject to subject queue",
      parameters: params
    )
  end

  def self.seen_before(queue, new_enq)
    if uss = UserSeenSubject.where(user: queue.user, workflow: queue.workflow).first
      SetMemberSubject.where(id: new_enq)
        .joins(:subject)
        .where(subjects: { id: uss.subject_ids })
    else
      SetMemberSubject.none
    end
  end

  def self.enqueue_sms_ids(queue, enqd_non_dup_sms_ids)
    seen_before_set = seen_before(queue, enqd_non_dup_sms_ids)
    dup_ids = if seen_before_set.exists?
      notify_dup_subject_seen_before_error(queue, seen_before_set)
      seen_before_set.map(&:id)
    else
      []
    end
    enqd_non_dup_sms_ids - dup_ids
  end
end
