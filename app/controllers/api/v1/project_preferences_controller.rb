class Api::V1::ProjectPreferencesController < Api::ApiController
  include PreferencesController

  require_authentication :all, scopes: [:project]
  schema_type :json_schema

  def update_project_settings
    binding.pry
    project = Project.find params[:project_id]
    unless required_params
      render json: { error: 'missing or invalid params' }, status: :unprocessable_entity
    end
    if project.owner?(api_user.user)
      upp = UserProjectPreference.find_or_initialize_by(project: project, user_id: api_user.user)
      upp.settings.merge! params[:settings]
      if upp.save!
        render status: :ok, nothing: true
      else
        render status: :unprocessable_entity, nothing: true
      end
    else
      render json: { error: 'not authorized' }, status: :not_authorized
    end
  end

  private

  def required_params
    params_to_check = [ params[:project_id], params[:user_id], params[:settings] ]
    params_to_check.all? { |param| !param.blank? }
  rescue JsonSchema::ValidationError,
    ActionController::ParameterMissing,
    ActionDispatch::ParamsParser::ParseError
    return false
  end

  def resource_name
    "project_preference"
  end
end
