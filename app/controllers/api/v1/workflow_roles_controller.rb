class Api::V1::WorkflowRolesController < Api::ApiController
  include RolesController
  require_authentication :create, :update, :destroy, scopes: [:project]

  allowed_params :create, roles: [], links: [:user, :workflow]
  allowed_params :update, roles: []

  def resource_name
    'workflow_role'
  end
end
