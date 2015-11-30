class Api::V1::MembershipsController < Api::ApiController
  before_filter :require_login
  require_authentication :all, scopes: [:group]
  resource_actions :index, :show, :create, :update, :deactivate
  schema_type :strong_params

  allowed_params :create, links: [:user, :user_group]
  allowed_params :update, :state

  private

  def add_active_resources_scope
    false
  end
end
