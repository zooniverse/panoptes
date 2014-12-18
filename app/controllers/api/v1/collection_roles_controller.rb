class Api::V1::CollectionRolesController < Api::ApiController
  include RolesController

  prepend_before_filter :require_login
  doorkeeper_for :all, scopes: [:collection]
  schema_type :strong_params

  allowed_params :create, roles: [], links: [:user, :collection]
  allowed_params :update, roles: []

  def resource_name
    "collection_role"
  end
end
