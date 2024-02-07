class Api::V1::ProjectPreferencesController < Api::ApiController
  include JsonApiController::PunditPolicy
  include PreferencesController

  require_authentication :all, scopes: [:project]
  resource_actions :create, :update, :show, :index, :update_settings
  extra_schema_actions :update_settings
  schema_type :json_schema
  before_action :find_upp_for_update_settings, only: [:update_settings]
  before_action :find_project, only: [:read_settings]

  def read_settings
    skip_policy_scope
    read_and_update_settings_response
  end

  def update_settings
    skip_policy_scope
    @upp.settings.merge! params_for[:settings]
    @upp.save!
    read_and_update_settings_response
  end

  def find_project
    @project = Project.find(params[:project_id])
  end

  def find_upp_for_update_settings
    @upp = UserProjectPreference.find_by!(
      user_id: params_for[:user_id],
      project_id: params_for[:project_id]
    )
    raise Api::Unauthorized, 'You must be the project owner or a collaborator' unless user_allowed?
  end

  def user_allowed?
    @upp.project.owners_and_collaborators.include?(api_user.user) || api_user.is_admin?
  end

  def read_and_update_settings_response
    set_last_modified_header if action_name == 'update_settings'

    render_json_response
  end

  def set_last_modified_header
    response.headers['Last-Modified'] = @upp.updated_at.httpdate
  end

  def render_json_response
    if action_name == 'update_settings'
      preferences = UserProjectPreference.where(id: @upp.id)
    else
      preferences = @project.user_project_preference.where.not(email_communication: nil)
      preferences = params[:user_id].present? ? preferences.where(user_id: params[:user_id]) : preferences
    end  

    render(
      status: :ok,
      json_api: serializer.resource({}, preferences, context)
    )
  end
end
