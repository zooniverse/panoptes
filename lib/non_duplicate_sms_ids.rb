class NonDuplicateSmsIds

  attr_reader :queue, :append_ids, :curr_queue_ids

  def initialize(queue, append_ids)
    @queue = queue
    @curr_queue_ids = queue.set_member_subject_ids
    @append_ids = append_ids
  end

  def enqueue_sms_ids_set
    check_dup_subject_enqueue_error
    enqueue_dup_set = dup_incoming_ids | dup_seen_before_ids
    new_append_non_dup_ids = (append_ids - enqueue_dup_set)
    (curr_queue_ids | new_append_non_dup_ids).uniq
  end

  private

  def check_dup_subject_enqueue_error
    notify_dup_subject_enqueue_error
    notify_unbound_queue_growth
  end

  def dup_incoming_ids
    @dup_incoming_ids ||= append_ids & curr_queue_ids
  end

  def unbound_queue_growth?
    future_size = curr_queue_size + append_ids_size
    threshold_limit = SubjectQueue::DEFAULT_LENGTH * 2
    future_size > threshold_limit
  end

  def dup_seen_before_ids
    notify_dup_subject_seen_before_error
    seen_before_set.map(&:id)
  end

  def user
    queue.user
  end

  def workflow
    queue.workflow
  end

  def curr_queue_size
    curr_queue_ids.size
  end

  def append_ids_size
    append_ids.length
  end

  def seen_before_set
    @seen_before ||= if user_seen_subject
      SetMemberSubject.where(id: append_ids)
        .joins(:subject)
        .where(subjects: { id: user_seen_subject.subject_ids })
    else
      SetMemberSubject.none
    end
  end

  def user_seen_subject
    UserSeenSubject.where(user: user, workflow: workflow).first
  end

  def error_params
    error_params = {
      user_id: queue.user.id,
      workflow_id: queue.workflow.id,
      curr_queue_size: curr_queue_size,
      append_ids_size: append_ids_size,
      dup_incoming_ids: dup_incoming_ids
    }
    if seen_before_set.exists?
      error_params.merge!({
        seen_before_sms_ids: seen_before_set.map(&:id),
        seen_before_subject_ids: seen_before_set.map(&:subject_id)
      })
    end
    error_params
  end

  def notify_honey_badger(error_class, error_message)
    Honeybadger.notify(
      error_class:   "Subject Queue #{error_class}",
      error_message: error_message,
      parameters:  error_params
    )
  end

  def notify_dup_subject_enqueue_error
    unless dup_incoming_ids.empty?
      notify_honey_badger("Duplicates", "Appending duplicates to subject queue")
    end
  end

  def notify_unbound_queue_growth
    if unbound_queue_growth?
      notify_honey_badger("Unbound Growth", "Queue is growing too large")
    end
  end

  def notify_dup_subject_seen_before_error
    if seen_before_set.exists?
      notify_honey_badger("Seen Before", "Appending seen before subject to subject queue")
    end
  end
end
