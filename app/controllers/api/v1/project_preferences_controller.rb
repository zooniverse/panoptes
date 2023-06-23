class Api::V1::ProjectPreferencesController < Api::ApiController
  include JsonApiController::PunditPolicy
  include PreferencesController

  require_authentication :all, scopes: [:project]
  resource_actions :create, :update, :show, :index, :update_settings
  extra_schema_actions :update_settings
  schema_type :json_schema
  before_action :find_upp_for_update_settings, only: [:update_settings]

  def update_settings
    skip_policy_scope
    @upp.settings.merge! params_for[:settings]
    @upp.save!
    update_settings_response
  end

  private

  def find_upp_for_update_settings
    @upp = UserProjectPreference.find_by!(
      user_id: params_for[:user_id],
      project_id: params_for[:project_id]
    )
    raise Api::Unauthorized, 'You must be the project owner or a collaborator' unless user_allowed?
  end

  def user_allowed?
    @upp.project.owners_and_collaborators.include?(api_user.user) || api_user.user.is_admin?
  end

  def update_settings_response
    response.headers['Last-Modified'] = @upp.updated_at.httpdate
    render(
      status: :ok,
      json_api: serializer.resource(
        {},
        UserProjectPreference.where(id: @upp.id),
        context
      )
    )
  end
end
