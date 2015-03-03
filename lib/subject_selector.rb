class SubjectSelector
  class MissingParameter < StandardError; end

  attr_reader :user, :params

  def initialize(user, params, scope, session)
    @user, @params, @scope, @session = user, params, scope, session
  end

  def queued_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    user_enqueued = UserSubjectQueue
                    .find_by!(user: user.user, workflow_id: params[:workflow_id])
    selected_subjects(user_enqueued.next_subjects(default_page_size))
  end

  def cellect_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    selected_subjects(CellectClient.get_subjects(*cellect_params))
  end

  def selected_subjects(subject_ids)
    subjects = @scope.where(id: subject_ids)
    subjects
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
