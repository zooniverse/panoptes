class SubjectSelector
  class MissingParameter < StandardError; end
  
  attr_reader :user, :params

  def initialize(user, params)
    @user, @params = user, params
  end

  def create_response
    case params[:sort]
    when 'cellect'
      cellect_subjects
    when 'queued'
      queued_subjects
    else
      query_subjects
    end
  end
  
  def queued_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    user_enqueued = UserSubjectQueue
      .find_by(user: user.user, workflow_id: params[:workflow_id])
    selected_subjects(user_enqueued.sample_subjects(10 || params[:limit]))
  end

  def cellect_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    selected_subjects(Cellect::Client.connection.get_subjects(**cellect_params))
  end
  
  def query_subjects
    SubjectSerializer.page(params)
  end

  def selected_subjects(subject_ids)
    SubjectSerializer.page({}, Subject.where(id: SetMemberSubject.where(id: subject_ids).select(:subject_id)))
  end

  private

  def workflow_id_error
    MissingParameter.new("workflow_id parameter missing")
  end
  
  def cellect_params
    c_params = params.permit(:sort, :workflow_id, :subject_set_id, :limit, :host)
    c_params[:user_id] = user.id
    c_params[:limit] ||= 10
    c_params[:group_id] = c_params.delete(:subject_set_id)
    c_params.delete(:sort)
    c_params.symbolize_keys
  end
end
