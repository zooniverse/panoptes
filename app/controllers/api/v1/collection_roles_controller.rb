class Api::V1::CollectionRolesController < Api::ApiController
  include JsonApiController::PunditPolicy
  include RolesController

  require_authentication :create, :update, :destroy, scopes: [:collection]

  allowed_params :create, roles: [], links: [:user, :collection]
  allowed_params :update, roles: []
end
