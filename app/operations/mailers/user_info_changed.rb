module Mailers
  class UserInfoChanged < Operation

    integer :user_id
    string :changed

    def execute
      UserInfoChangedMailerWorker.perform_async(user.id, changed)
    end
  end
end
