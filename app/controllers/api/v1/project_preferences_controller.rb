class Api::V1::ProjectPreferencesController < Api::ApiController
  include PreferencesController

  require_authentication :all, scopes: [:project]
  schema_type :json_schema
  before_action :require_project_ownership, only: [:update_project_settings]

  def update_project_settings
    upp = UserProjectPreference.find_or_initialize_by(project: project, user_id: api_user.user)
    upp.settings.merge! params[:settings]
    if upp.save!
      render status: :ok, nothing: true
    else
      render status: :unprocessable_entity, nothing: true
    end
  end

  private

  def project
    Project.find params[:project_id]
  end

  def require_project_ownership
    unless project.owner?(api_user.user) do
      render json: { error: 'not authorized' }, status: :not_authorized
    end
  end

  def resource_name
    "project_preference"
  end
end
