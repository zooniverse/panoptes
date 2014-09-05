class Api::V1::ClassificationsController < Api::ApiController
  doorkeeper_for :show, :index, :destory, :update, scopes: [:classification]
  access_control_for :update, :destroy, resource_class: Classification

  def show
    render json_api: serializer.resource(params, visible_scope)
  end

  def index
    render json_api: serializer.page(params, visible_scope)
  end

  def create
    classification = Classification.new(create_params)

    if classification.save! && api_user.logged_in? 
      update_seen_subjects
      update_cellect
      create_project_preference
    end
    
    json_api_render(201,
                    serializer.resource(classification),
                    api_classification_url(classification))
  end

  def update
    # TODO
  end

  private

  def visible_scope
    Classification.visible_to(api_user)
  end

  def create_project_preference
    UserProjectPreference.where(user: api_user.user, **preference_params)
      .first_or_create do |up|
      up.email_communication = api_user.user.project_email_communication
      up.preferences = {}
    end
  end

  def update_seen_subjects
    UserSeenSubjectUpdater
      .update_user_seen_subjects(user_seen_subject_params)
  end

  def update_cellect
    Cellect::Client.connection.add_seen(**cellect_params)
  end

  def cellect_params
    classification_params
      .slice(:workflow_id, :subject_id)
      .merge(user_id: api_user.id,
             host: cellect_host(params[:workflow_id]))
      .symbolize_keys
  end

  def preference_params
    classification_params.slice(:project_id).symbolize_keys
  end

  def classification_params
    params.require(:classifications)
      .permit(:project_id,
              :workflow_id,
              :set_member_subject_id,
              :subject_id,
              :completed,
              annotations: [:value,
                            :key,
                            :started_at,
                            :finished_at,
                            :user_agent])
  end

  def create_params
    classification_params
      .slice(:project_id,
             :workflow_id,
             :set_member_subject_id,
             :completed,
             :annotations)
      .merge(user_ip: request_ip,
             user_id: api_user.user.try(:id))
  end

  def user_seen_subject_params
    classification_params
      .slice(:subject_id, :workflow_id)
      .merge(user_id: api_user.user.try(:id))
      .symbolize_keys
  end
end
