class SubjectSelector
  class MissingParameter < StandardError; end
  class MissingSubjectQueue < StandardError; end

  attr_reader :user, :params, :workflow

  def initialize(user, workflow, params, scope)
    @user, @workflow, @params, @scope = user, workflow, params, scope
  end

  def queued_subjects
    raise workflow_id_error unless workflow
    raise group_id_error if needs_set_id?

    queue, context = retrieve_subject_queue

    if queue
      selected_subjects(queue.next_subjects(default_page_size), context)
    else
      raise MissingSubjectQueue.new("No queue defined for user. Building one now, please try again.")
    end
  end

  def selected_subjects(sms_ids, selector_context={})
    subjects = @scope.eager_load(:set_member_subjects)
      .where(set_member_subjects: {id: sms_ids})
    [subjects, selector_context.merge(selected: true)]
  end

  private

  def needs_set_id?
    workflow.grouped && !params.has_key?(:subject_set_id)
  end

  def workflow_id_error
    MissingParameter.new("workflow_id parameter missing")
  end

  def group_id_error
    MissingParameter.new("subject_set_id parameter missing for grouped workflow")
  end

  def default_page_size
    params[:page_size] ||= 10
  end

  def retrieve_subject_queue
    queue_user, context = if workflow.finished? || user.has_finished?(workflow)
                            [nil, {workflow: workflow,
                                   user_seen: UserSeenSubject.where(user: user.user, workflow: workflow)}]
                          else
                            [user.user, {}]
                          end

    queue = SubjectQueue.scoped_to_set(params[:subject_set_id])
      .find_by(user: queue_user, workflow: workflow)

    case
    when queue.nil?
      queue = SubjectQueue.create_for_user(workflow, user.user, set: params[:subject_set_id])
    when queue.below_minimum?
      SubjectQueueWorker.perform_async(workflow.id, user.id)
    end
    [queue, context]
  end
end
