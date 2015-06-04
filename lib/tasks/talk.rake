# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :talk do
  desc "import owners and collaborators as admins of their talk instances"
  task create_admins: :environment do
    client = TalkApiClient.new
    Project.find_each do |project|
      project.create_talk_admin client
    end
  end
end
