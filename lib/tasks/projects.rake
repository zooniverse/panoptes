# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :projects do
  desc "create a project's volunteer names page"
  task :create_volunteer_names_page, [:project_id] => :environment do |t, args|
    project = Project.find(args[:project_id])
    # ensure there is an acknowledgement page before collecting all the names
    project_page_params = {
      language: project.primary_language,
      title: 'Volunteers',
      url_key: 'volunteers',
    }
    # find the volunteers project page if it exists
    project_page = ProjectPage.where(project_page_params).first
    unless project_page
      # create the project page if it doesn't exist
      project_page = ProjectPage.create!(project_page_params)
    end

    # collect all the sanitized user credited names for the project .... in batches
    volunteer_names = []

    user_project_prefs = UserProjectPreference.where(project_id: project.id).select(:id, :user_id)
    user_project_prefs.find_in_batches do |upp_batch|
      user_ids = upp_batch.pluck(:user_id)
      users = User.where(user_ids).select(:id, :login, :credited_name)
      users.find_each do |user|
        binding.pry
        volunteer_names << user.sanitized_credited_name
      end
    end

    # overwrite the project page content field with the sanitized volunteer names
    project_page.update(:content, volunteer_names.join(', '))
  end
end
