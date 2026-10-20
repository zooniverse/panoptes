class Api::V1::CollectionRolesController < Api::ApiController
  include JsonApiController::PunditPolicy
  include RolesController

  require_authentication :create, :update, :destroy, scopes: [:collection]

  allowed_params :create, roles: [], links: [:user, :collection]
  allowed_params :update, roles: []

  def create
    super
    if new_roles_present?(roles)
      UserAddedToCollectionMailerWorker.perform_async(
        new_user_id,
        collection_id,
        roles
      )
    end
  end

  def update
    previous_roles = controlled_resource.roles.dup
    super
    if new_roles_present?(roles, previous_roles)
      UserAddedToCollectionMailerWorker.perform_async(
        acl_user_id,
        controlled_resource.resource.id,
        roles
      )
    end
  end

  private

  def acl_user_id
    controlled_resource.user_group.users.first.id.to_i
  end

  def new_user_id
    params.dig(:collection_roles, :links, :user).to_i
  end

  def collection_id
    params.dig(:collection_roles, :links, :collection).to_i
  end

  def roles
    params.dig(:collection_roles, :roles)
  end

  def new_roles_present?(roles, previous_roles=[])
    return false if roles.blank?

    new_roles = %w[collaborator viewer contributor]
    (new_roles & (roles - previous_roles)).present?
  end
end
