# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :talk do
  desc "import owners and collaborators as admins of their talk instances"
  task :create_admins do
    client = TalkApiClient.new
    Project.find_each(&:create_talk_admin)
  end
end
