class SubjectSelector
  class MissingParameter < StandardError; end
  class MissingSubjectQueue < StandardError; end
  class MissingSubjectSet < StandardError; end
  class EmptyDatabaseSelect < StandardError; end

  attr_reader :user, :params, :workflow

  def initialize(user, workflow, params, scope)
    @user, @workflow, @params, @scope = user, workflow, params, scope
  end

  def queued_subjects
    raise workflow_id_error unless workflow
    raise group_id_error if needs_set_id?
    raise missing_subject_set_error if workflow.subject_sets.empty?
    unless queue = user_subject_queue
      raise MissingSubjectQueue.new("No queue defined for user. Building one now, please try again.")
    end
    subjects = selected_subjects(sms_ids_from_queue(queue))
    [ subjects, queue_context.merge(selected: true, url_format: :get) ]
  end

  def selected_subjects(sms_ids)
    @scope.eager_load(:set_member_subjects)
      .where(set_member_subjects: {id: sms_ids})
      .order("idx(array[#{sms_ids.join(',')}], set_member_subjects.id)")
  end

  private

  def sms_ids_from_queue(queue)
    set_member_subject_ids = queue.next_subjects(subjects_page_size)
    if set_member_subject_ids.blank?
      select_from_database
    else
      dequeue_subject(set_member_subject_ids)
      if queue.below_minimum?
        EnqueueSubjectQueueWorker.perform_async(workflow.id, queue_user.try(:id), params[:subject_set_id])
      end
      set_member_subject_ids
    end
  end

  def select_from_database
    sms_ids = PostgresqlSelection.new(workflow, user.user)
      .select(limit: 5, subject_set_id: params[:subject_set_id])
    empty_database_select_error if sms_ids.blank?
    sms_ids
  end

  def needs_set_id?
    workflow.grouped && !params.has_key?(:subject_set_id)
  end

  def workflow_id_error
    MissingParameter.new("workflow_id parameter missing")
  end

  def group_id_error
    MissingParameter.new("subject_set_id parameter missing for grouped workflow")
  end

  def missing_subject_set_error
    MissingSubjectSet.new("no subject set is associated with this workflow")
  end

  def empty_database_select_error
    message = params[:subject_set_id] ? "for subject_set_id = #{params[:subject_set_id]}" : nil
    raise EmptyDatabaseSelect.new("No data #{message} available for selection".squish)
  end

  def subjects_page_size
    page_size = params[:page_size] ? params[:page_size].to_i : 10
    params.merge!(page_size: page_size)
    page_size
  end

  def finished_workflow?
    @finished_workflow ||= workflow.finished? || user.has_finished?(workflow)
  end

  def queue_user
    @queue_user ||= finished_workflow? ? nil : user.user
  end

  def queue_context
    @queue_context ||= if finished_workflow?
      {workflow: workflow, user_seen: UserSeenSubject.where(user: user.user, workflow: workflow)}
    else
      {}
    end
  end

  def user_subject_queue
    queue = SubjectQueue.by_set(params[:subject_set_id])
      .find_by(user: queue_user, workflow: workflow)
    return queue if queue
    SubjectQueue.create_for_user(workflow, queue_user, set_id: params[:subject_set_id])
  end

  def dequeue_subject(set_member_subject_ids)
    SubjectQueue.dequeue(workflow, set_member_subject_ids, user: user.user,
      set_id: params[:subject_set_id])
  end
end
