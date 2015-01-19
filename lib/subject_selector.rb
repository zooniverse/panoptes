class SubjectSelector
  class MissingParameter < StandardError; end

  attr_reader :user, :params

  def initialize(user, params, scope, host)
    @user, @params, @scope, @host = user, params, scope, host
  end

  def create_response
    case params[:sort]
    when 'cellect'
      cellect_subjects
    when 'queued'
      queued_subjects
    else
      @scope
    end
  end

  def queued_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    user_enqueued = UserSubjectQueue
      .find_by!(user: user.user, workflow_id: params[:workflow_id])
    selected_subjects(user_enqueued.sample_subjects(10 || params[:limit]))
  end

  def cellect_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    selected_subjects(Cellect::Client.connection.get_subjects(**cellect_params))
  end

  def selected_subjects(subject_ids)
    set_member_subjects = SetMemberSubject.where(id: subject_ids).select(:subject_id)
    subjects = @scope.where(id: set_member_subjects)
    subjects
  end

  private

  def workflow_id_error
    MissingParameter.new("workflow_id parameter missing")
  end

  def cellect_params
    {
      workflow_id: params[:workflow_id],
      group_id: params[:subject_set_id],
      limit: params[:per_page] || 10,
      host: @host,
      user_id: user.id
    }
  end
end
