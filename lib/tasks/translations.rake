# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :translations do

  def create_or_update_translation_strings(resource, language)
    translation = Translation.find_or_initialize_by(translated: resource, language: language)
    translated_strings = TranslationStrings.new(resource).extract
    translation.strings = translated_strings
    translation.save!
  end

  desc "Sync existing translatable resources with new translations data model"
  task :sync_resource_strings, [:project_id] => [:environment] do |task, args|
    project = Project.find(args[:project_id])
    language = project.primary_language

# TODO: extract all these steps to a worker
    puts "Syncing project - #{project.id} strings to translations"
    create_or_update_translation_strings(project, language)

    puts "Syncing all project workflow strings to translations"
    project.workflows.each do |workflow|
      create_or_update_translation_strings(workflow, language)
    end

    puts "Syncing all project field guide strings to translations"
    project.field_guides.each do |field_guide|
      create_or_update_translation_strings(field_guide, language)
    end

    puts "Syncing all project tutorial strings to translations"
    project.tutorials.each do |tutorial|
      create_or_update_translation_strings(tutorial, language)
    end

    puts "Syncing all project page strings to translations"
    project.pages.each do |page|
      create_or_update_translation_strings(page, language)
    end

    if organization = project.organization
      puts "Syncing project organization strings to translations"
      create_or_update_translation_strings(organization, language)

      puts "Syncing project organization page strings to translations"
      organization.pages.each do |page|
        create_or_update_translation_strings(page, language)
      end
    end
  end
end
