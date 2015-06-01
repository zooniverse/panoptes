# -*- mode: ruby -*-
# vi: set ft=ruby :
require_relative '../export/export_json_project'

namespace :project do

  namespace :json do
    desc "Export to file, a json dump of a project, primary-content, workflows & primary-content, avatar and background"
    task export: :environment do
      project_ids = Array.wrap(ENV['EXPORT_PROJECT_IDS'].try(:split, ","))
      project_ids.each do |project_id|
        out_file_path = "#{Rails.root}/tmp/json_project_dump_id_#{project_id}.json"
        File.open(out_file_path, 'w') do |file|
          file.write(Export::JSON::Project.new(project_id).to_json)
        end
        puts "Exported project with ID: #{project_id} to file: #{out_file_path}."
      end
    end
  end
end
