class SubjectSelector
  class MissingParameter < StandardError; end

  attr_reader :user, :params, :workflow

  def initialize(user, workflow, params, scope, session)
    @user, @workflow, @params, @scope, @session = user, workflow, params, scope, session
  end

  def queued_subjects
    raise workflow_id_error unless workflow
    user_enqueued = UserSubjectQueue
                    .find_by!(user: user.user, workflow_id: params[:workflow_id])
    selected_subjects(user_enqueued.next_subjects(default_page_size))
  end

  def cellect_subjects
    raise workflow_id_error unless workflow
    subjects = CellectClient.get_subjects(*cellect_params)
    selector_context = {}
    if subjects.blank?
      subjects = PostgresqlSelection.new(workflow, user)
                 .select(limit: default_page_size, subject_set_id: params[:subject_set_id])
      selector_context = { retired: workflow.finished?,
                           already_seen: user.has_finished?(workflow) }
    end
    selected_subjects(subjects, selector_context)
  end

  def selected_subjects(subject_ids, selector_context={})
    subjects = @scope.where(id: subject_ids)
    [subjects, selector_context]
  end

  private
  
  def workflow_id_error
    MissingParameter.new("workflow_id parameter missing")
  end

  def cellect_params
    [@session,
     params[:workflow_id],
     user.id,
     params[:subject_set_id],
     default_page_size]
  end

  def default_page_size
    params[:page_size] ||= 10
  end
end
