class Api::V1::ProjectPreferencesController < Api::ApiController
  include JsonApiController::PunditPolicy
  include PreferencesController

  require_authentication :all, scopes: [:project]
  resource_actions :create, :update, :show, :index, :update_settings
  extra_schema_actions :update_settings
  schema_type :json_schema
  before_action :find_upp, only: %i[update_settings]

  def read_settings
    skip_policy_scope
    project = Project.find(params[:project_id])
    raise Api::Unauthorized, 'You must be the project owner or a collaborator' unless user_allowed?(project)

    upp_list = fetch_upp_list

    render(
      status: :ok,
      json_api: serializer.page(
        params,
        upp_list,
        send_settings_context
      )
    )
  end

  def update_settings
    skip_policy_scope
    @upp.settings.merge! params_for[:settings]
    @upp.save!
    response.headers['Last-Modified'] = @upp.updated_at.httpdate

    render(
      status: :ok,
      json_api: serializer.resource(
        {},
        UserProjectPreference.where(id: @upp.id),
        send_settings_context
      )
    )
  end

  def find_upp
    @upp = UserProjectPreference.find_by!(
      user_id: params_for[:user_id],
      project_id: params_for[:project_id]
    )
    raise Api::Unauthorized, 'You must be the project owner or a collaborator' unless user_allowed?(@upp.project)
  end

  def fetch_upp_list
    upp_list = UserProjectPreference.where(project_id: params[:project_id]).where.not(email_communication: nil)
    upp_list = upp_list.where(user_id: params[:user_id]) if params[:user_id].present?
    upp_list
  end

  def user_allowed?(project)
    project.owners_and_collaborators.include?(api_user.user) || api_user.is_admin?
  end

  def send_settings_context
    {
      include_settings?: true,
      include_email_communication?: false,
      include_legacy_count?: false,
      include_preferences?: false,
      include_activity_count?: false,
      include_activity_count_by_workflow?: false
    }
  end
end
