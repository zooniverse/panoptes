class SeenSubjectRemover

  attr_reader :user, :workflow, :append_ids, :curr_queue_ids

  def initialize(user, workflow, append_ids)
    @user = user
    @workflow = workflow
    @append_ids = append_ids
    notify_dup_subject_seen_before_error
  end

  def ids_to_enqueue
    append_ids - seen_before_set
  end

  private

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
                     end.pluck(:id)
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
    unless seen_before_set.blank?
      error_params.merge!({
        seen_before_sms_ids: seen_before_set
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
    unless seen_before_set.blank?
      notify_honey_badger("Seen Before", "Appending seen before subject to subject queue")
    end
  end
end
