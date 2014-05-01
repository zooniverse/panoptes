# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :user do
  desc 'import comma seperated list of users from Zoo Home'
  task import: :environment do
    ENV['USERS'].split(",").each do |user|
      user = ZooniverseUser.where(login: user).first
      u = User.create do |u|
        u.login = user.login
        u.email = user.email
        u.created_at = user.created_at
        u.encrypted_password = user.crypted_password
        u.password_salt = user.password_salt
        u.name = user.name
        u.display_name = user.display_name
        u.zooniverse_id = user.id
        u.hash_func = 'sha1'
      end
      u.save!
    end
  end
end
