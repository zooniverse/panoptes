class Api::V1::ProjectRolesController < Api::ApiController
  include RolesController

  before_filter :format_filter_params, only: :index
  skip_before_filter :require_login, only: :index

  doorkeeper_for :show, :create, :update, scopes: [:project]
  schema_type :strong_params

  allowed_params :create, roles: [], links: [:user, :project]

  allowed_params :update, roles: []

  def resource_name
    "project_role"
  end

  private

  def format_filter_params
    if project_id_filter = params.delete(:project_id)
      params[:resource_id] = project_id_filter
    end
  end
end
