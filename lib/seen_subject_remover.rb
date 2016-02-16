class SeenSubjectRemover

  attr_reader :user, :workflow, :append_ids, :curr_queue_ids

  def initialize(user, workflow, append_ids)
    @user = user
    @workflow = workflow
    @append_ids = append_ids
  end

  def ids_to_enqueue
    append_ids - seen_before_set
  end

  private

  def append_ids_size
    append_ids.length
  end

  def seen_before_set
    @seen_before ||=
      if user_seen_subject
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
end
