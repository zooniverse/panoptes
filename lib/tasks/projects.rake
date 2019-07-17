# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :projects do
  desc "create list of volunteer names for a project's acknowledgement page"
  task :create_user_acknowledgement_page, [:project_id] => :environment do |t, args|
    known_user_names = []

    user_project_prefs = UserProjectPreference.where(project_id: args[:project_id]).select(:id, :user_id)
    user_project_prefs.find_in_batches do |upp_batch|

      user_ids = upp_batch.pluck(:user_id)
      users = User.where(user_ids).select(:id, :login, :credited_name)
      users.find_each do |user|
        binding.pry
        known_user_names << user.sanitized_credited_name
      end
    end
  end
end
