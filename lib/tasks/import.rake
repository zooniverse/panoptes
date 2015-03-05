# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :user do
  desc 'import comma seperated list of users from Zoo Home'
  task import: :environment do
    users = ENV['USERS'].try(:split, ",")
    ZooniverseUser.import_users(users)
  end
end
