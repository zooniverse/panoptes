module Mailers
  class UserInfoChanged < Operation
    string :changed

    def execute
      UserInfoChangedMailerWorker.perform_async(api_user.id, changed)
    end
  end
end
