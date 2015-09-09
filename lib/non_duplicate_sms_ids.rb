class NonDuplicateSmsIds

  attr_reader :user, :workflow, :append_ids, :curr_queue_ids

  def initialize(user, workflow, append_ids)
    @user = user
    @workflow = workflow
    @append_ids = append_ids
  end

  def ids_to_enqueue
    append_ids - dup_seen_before_ids
  end

  private

  def dup_seen_before_ids
    return @seen_before if @seen_before
    notify_dup_subject_seen_before_error
    @seen_before = seen_before_set.map(&:id)
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
    UserSeenSubject.where(user: user, workflow: workflow).first if user
  end

  def error_params
    error_params = {
      user_id: user.try(:id),
      workflow_id: workflow.id,
      append_ids_size: append_ids_size,
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

  def notify_dup_subject_seen_before_error
    if seen_before_set.exists?
      notify_honey_badger("Seen Before", "Appending seen before subject to subject queue")
    end
  end
end
