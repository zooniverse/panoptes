# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :user do
  desc 'import comma seperated list of users from Zoo Home'
  task import: :environment do
    users = ENV['USERS'].try(:split, ",")
    (users.blank? ? ZooniverseUser.find_each : ZooniverseUser.where(login: users)).each do |user|
      u = User.create! do |u|
        p "Importing #{user.login}"
        u.display_name = user.login
        u.email = user.email
        u.created_at = user.created_at
        u.updated_at = user.updated_at
        u.encrypted_password = user.crypted_password
        u.password_salt = user.password_salt
        u.zooniverse_id = user.id
        u.hash_func = 'sha1'
        u.migrated = true
        u.build_identity_group
      end
    end
  end
end
