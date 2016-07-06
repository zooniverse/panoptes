module Mailers
  class UserAddedToProject < Operation
    integer :resource_id
    array :roles

    def execute
      UserAddedToProjectMailerWorker.perform_async(api_user.id, resource_id, roles)
    end
  end
end
