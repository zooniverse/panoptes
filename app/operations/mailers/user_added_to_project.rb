module Mailers
  class UserAddedToProject < Operation

    integer :user_id
    integer :resource_id
    array :roles

    def execute
      UserAddedToProjectMailerWorker.perform_async(id, resource.id, check_new_roles(params)) if check_new_roles(params).present?
    end

    def check_new_roles(roles)
      diff = roles ? roles[1].sort - roles[0].sort : []
      ["collaborator", "expert"] & diff
    end
  end
end
