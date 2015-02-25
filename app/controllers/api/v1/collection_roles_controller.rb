class Api::V1::CollectionRolesController < Api::ApiController
  include RolesController
  doorkeeper_for :create, :update, scopes: [:collection]

  allowed_params :create, roles: [], links: [:user, :collection]
  allowed_params :update, roles: []

  def resource_name
    "collection_role"
  end
end
