# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :user do
  desc 'import comma seperated list of users from Zoo Home'
  task import: :environment do
    users = ENV['USERS'].try(:split, ",")
    ZooniverseUser.import_users(users)
  end
end

namespace :user_project_preference do
  desc 'import comma seperated list of users project preferences (subscriptions) from Zoo Home'
  task import: :environment do
    users = ENV['USERS'].try(:split, ",")
    ZooniverseUserSubscription.import_zoo_user_subscriptions(users)
  end
end

namespace :project do
  desc 'import comma seperated list of projects from Zoo Home'
  task import: :environment do
    projects = ENV['PROJECTS'].try(:split, ",")
    ZooniverseProject.import_zoo_projects(projects)
  end

  namespace :json do
    desc "Import from file a json dump of a project, primary-content, workflows & primary-content, avatar and background"
    task import: :environment do
      json_dump_file_path = "#{ENV['JSON_PROJECT_DUMP_PATH']}"
      new_owner = User.find(ENV['PROJECT_OWNER_ID'])
      dump_data = JSON.parse(File.read(json_dump_file_path))

      required_keys = %w( project project_avatar project_background project_content workflows workflow_contents )
      required_keys.each do |req_key|
        raise("Missing the #{req_key} key from the data dump") unless dump_data.has_key?(req_key)
      end
      if dump_data["workflows"].size != dump_data["workflow_contents"].size
        raise("Must have a workflow content for each workflow")
      end

      p = Project.new(dump_data["project"].merge(owner: new_owner))
      [].tap do |instances|
        instances << p
        p.project_contents << ProjectContent.new(dump_data["project_content"])
        instances << p.project_contents.first
        instances << p.avatar = Medium.new(dump_data["project_avatar"])
        instances << p.background = Medium.new(dump_data["project_background"])
        dump_data["workflows"].each_with_index do |workflow_attrs, index|
          w = Workflow.new(workflow_attrs.merge(project: p))
          w.workflow_contents << WorkflowContent.new(dump_data["workflow_contents"][index])
          instances << w << w.workflow_contents.first
        end
        ActiveRecord::Base.transaction { instances.map(&:save!) }

        puts "Imported project with ID: #{p.id} and SLUG: #{p.slug} to database."
      end
    end
  end
end
