class SubjectSelector
  class MissingParameter < StandardError; end
  
  attr_reader :user, :params

  def initialize(user, params)
    @user, @params = user, params
  end

  def create_response
    case params[:sort]
    when 'random'
      random_subjects
    when 'queued'
      queued_subjects
    else
      if params.has_key?(:subject_set_id)
        query_subject_sets
      else
        query_subjects
      end
    end
  end
  
  def queued_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    user_enqueued = UserSubjectQueue
      .find_by(user: user.user, workflow_id: params[:workflow_id])
    subjects = user_enqueued.sample_subjects(10 || params[:limit]).join(',')
    SetMemberSubjectSerializer.resource({id: subjects})
  end

  def random_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    subject_ids = Cellect::Client.connection.get_subjects(**cellect_params).join(',')
    SetMemberSubjectSerializer.page({id: subject_ids})
  end
  
  def query_subjects
    SubjectSerializer.page(params)
  end

  def query_subject_sets
    SetMemberSubjectSerializer.page(params)
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
