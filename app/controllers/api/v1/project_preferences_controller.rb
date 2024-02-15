class Api::V1::ProjectPreferencesController < Api::ApiController
  include JsonApiController::PunditPolicy
  include PreferencesController

  require_authentication :all, scopes: [:project]
  resource_actions :create, :update, :show, :index, :update_settings
  extra_schema_actions :update_settings
  schema_type :json_schema
  before_action :find_upp, only: [:update_settings, :read_settings]

  def read_settings
    skip_policy_scope
    render(
      status: :ok,
      json_api: serializer.page(
        params,
        @upp_list,
        context
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
        @upp_list,
        context
      )
    )
  end

  def find_upp
    @upp_list = action_name == 'read_settings' ? UserProjectPreference.where(project_id: params[:project_id], email_communication: !nil) : UserProjectPreference.where(user_id: params_for[:user_id], project_id: params_for[:project_id])

    @upp = @upp_list.first
    raise ActiveRecord::RecordNotFound unless @upp.present?

    @upp_list = action_name == 'read_settings' && params[:user_id].present? ? @upp_list.where(user_id: params[:user_id]) : @upp_list

    raise Api::Unauthorized, 'You must be the project owner or a collaborator' unless user_allowed?
  end

  def user_allowed?
    @upp.project.owners_and_collaborators.include?(api_user.user) || api_user.is_admin?
  end
end
