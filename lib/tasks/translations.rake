# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :translations do

  def create_missing_translation_strings(resource, language)
    # do we have any existing translation for the project's primary language
    translation = Translation.find_or_initialize_by(translated: resource, language: language)
    if translation.new_record?
      # get the current resource primary language strings
      translated_strings = TranslationStrings.new(resource).extract
      # make sure they end up in a translation model with the correct version resources
      translation.update_strings_and_versions(translated_strings, translated_resource.latest_version_id)
      translation.save!
    else
      false
    end
  end

  desc "Sync a project's missing primary language translations"
  # call this with param sytnax
  # rake translations:sync_projects_missing_primary_lanugage_translations['1 2 3 4']
  # or
  # rake translations:sync_projects_missing_primary_lanugage_translations[1,2,3,4]
  # or
  # rake translations:sync_projects_missing_primary_lanugage_translations['1 2',3,4]
  task :sync_projects_missing_primary_lanugage_translations, [:project_ids] => [:environment] do |task, args|
    space_format_ids = args.project_ids.split
    extra_format_ids = args.extras
    project_ids = space_format_ids | extra_format_ids

    project_ids.each do |project_id|
      project = Project.find(project_id)

      primary_language = project.primary_language

      puts "Syncing project - #{project.id} strings to translations"
      puts create_missing_translation_strings(project, primary_language)

      puts 'Syncing all project workflow strings to translations'
      project.workflows.each do |workflow|
        puts create_missing_translation_strings(workflow, primary_language)
      end

      puts 'Syncing all project field guide strings to translations'
      project.field_guides.each do |field_guide|
        puts create_missing_translation_strings(field_guide, primary_language)
      end

      puts 'Syncing all project tutorial strings to translations'
      project.tutorials.each do |tutorial|
        puts create_missing_translation_strings(tutorial, primary_language)
      end

      puts 'Syncing all project page strings to translations'
      project.pages.each do |page|
        puts create_missing_translation_strings(page, primary_language)
      end

      organization = project.organization
      next unless organization

      puts 'Syncing project organization strings to translations'
      puts create_missing_translation_strings(organization, primary_language)

      puts 'Syncing project organization page strings to translations'
      organization.pages.each do |page|
        puts create_missing_translation_strings(page, primary_language)
      end
    end
  end
end
