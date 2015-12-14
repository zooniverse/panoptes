# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :project do
  namespace :json do
    desc "Import from file a json dump of a project, primary-content, workflows & primary-content, avatar and background"
    task import: :environment do
      json_dump_file_path = "#{ENV['JSON_PROJECT_DUMP_PATH']}"
      new_owner = User.find(ENV['PROJECT_OWNER_ID'])
      dump_data = JSON.parse(File.read(json_dump_file_path))

      required_data = %w(project project_content workflows workflow_contents)
      required_data.each do |req_key|
        raise("Missing the #{req_key} key from the data dump") unless dump_data[req_key]
      end
      if dump_data["workflows"].size != dump_data["workflow_contents"].size
        raise("Must have a workflow content for each workflow")
      end

      p = Project.new(dump_data["project"].merge(owner: new_owner))
      [].tap do |instances|
        instances << p
        p.project_contents << ProjectContent.new(dump_data["project_content"])
        instances << p.project_contents.first
        if avatar = dump_data["project_avatar"]
          instances << p.avatar = Medium.new(avatar)
        end
        if background = dump_data["project_background"]
          instances << p.background = Medium.new(background)
        end
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
