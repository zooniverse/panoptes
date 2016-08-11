class Api::V1::ProjectPreferencesController < Api::ApiController
  include PreferencesController

  require_authentication :all, scopes: [:project]
  extra_schema_actions :update_settings
  schema_type :json_schema
  before_action :require_project_ownership, only: [:update_project_settings]


  def update_settings
    upp = UserProjectPreference.find_or_initialize_by(project_id: params_for[:project_id],
                                                      user_id: params_for[:user_id])
    upp.settings.merge! params_for[:settings]
    if upp.save!
      render status: :ok, nothing: true
    else
      render status: :unprocessable_entity, nothing: true
    end
  end

  private

  def project
    Project.find params_for[:project_id]
  end

  def require_project_ownership
    unless project.owner?(api_user.user)
      render json: { error: 'not authorized' }, status: :not_authorized
    end
  end

  def resource_name
    "project_preference"
  end
end
