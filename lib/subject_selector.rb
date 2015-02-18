class SubjectSelector
  class MissingParameter < StandardError; end

  attr_reader :user, :params 

  def initialize(user, params, scope, host, controller)
    @user, @params, @scope, @host, @controller = user, params, scope, host, controller
  end

  def create_response
    case params[:sort]
    when 'cellect'
      @controller.render json_api: SubjectSerializer.page(params, cellect_subjects)
    when 'queued'
      @controller.render json_api: SubjectSerializer.page(params, queued_subjects)
    else
      if @controller.stale?(@scope)
        @controller.render json_api: SubjectSerializer.page(params, @scope)
      end
    end
  end

  def queued_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    user_enqueued = UserSubjectQueue
                    .find_by!(user: user.user, workflow_id: params[:workflow_id])
    selected_subjects(user_enqueued.next_subjects(10 || params[:limit]))
  end

  def cellect_subjects
    raise workflow_id_error unless params.has_key?(:workflow_id)
    selected_subjects(Cellect::Client.connection.get_subjects(**cellect_params))
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
    {
      workflow_id: params[:workflow_id],
      group_id: params[:subject_set_id],
      limit: params[:per_page] || 10,
      host: @host,
      user_id: user.id
    }
  end
end
