class Api::V1::ClassificationsController < Api::ApiController
  doorkeeper_for :show, :index, scopes: [:classifications]
  access_control_for :update, :destroy, resource_class: Classification

  def show
    render json_api: ClassificationSerializer.resource(params, visible_scope(api_user))
  end

  def index
    render json_api: ClassificationSerializer.page(params, visible_scope(api_user))
  end

  def create
    classification = Classification.new(creation_params)
    classification.user_ip = request_ip
    if api_user.logged_in?
      update_cellect
      classification.user = api_user.user
    end
    if classification.save!
      uss_params = user_seen_subject_params(api_user)
      UserSeenSubjectUpdater.update_user_seen_subjects(uss_params)
      create_project_preference
      json_api_render( 201,
                       ClassificationSerializer.resource(classification),
                       api_classification_url(classification) )
    end
  end

  def update
    # TODO
  end

  def destroy
    # TODO
  end

  private

  def visible_scope(actor)
    Classification.visible_to(actor)
  end

  def create_project_preference
    return unless api_user.logged_in?
    UserProjectPreference.where(user: api_user.user, **preference_params)
      .first_or_create do |up|
        up.email_communication = api_user.user.project_email_communication
        up.preferences = {}
      end
  end

  def update_cellect
    Cellect::Client.connection.add_seen(**cellect_params)
  end

  def classification_params
    params.require(:classification)
  end

  def permitted_cellect_params
    classification_params.permit(:workflow_id, :subject_id)
  end

  def cellect_params
    permitted_cellect_params
      .merge(user_id: api_user.id,
             host: cellect_host(params[:workflow_id]))
      .symbolize_keys
  end

  def preference_params
    classification_params.permit(:project_id).symbolize_keys
  end

  def creation_params
    permitted_attrs = [ :project_id,
                        :workflow_id,
                        :set_member_subject_id ]
    classification_params.permit(*permitted_attrs).tap do |white_listed|
      white_listed[:annotations] = params[:classification][:annotations]
    end
  end

  def user_seen_subject_params(user)
    params = permitted_cellect_params
               .slice(:subject_id, :workflow_id)
               .merge(user_id: user.id)
    params.symbolize_keys
  end
end
