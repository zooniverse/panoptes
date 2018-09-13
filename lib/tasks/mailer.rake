# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :mailer do

  namespace :users do
    desc "Email dormant users asking them to come back to the Zooniverse"

    task :dormant, [:num_days_since_activity, :only_user_ids_ending_in] => [:environment] do |t, args|
      EmailDormantUsersWorker.perform_async(
        args[:num_days_since_activity],
        args[:only_user_ids_ending_in]
      )
    end
  end
end
