# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'csv'

namespace :migrate do

  namespace :user do
    desc "Migrate beta email users from input text file"
    task beta_email_communication: :environment do
      user_emails = CSV.read("#{Rails.root}/beta_users.txt").flatten!

      raise "Empty beta file list" if user_emails.blank?

      beta_users = User.where(beta_email_communication: nil, email: user_emails)
      beta_users_count = beta_users.count
      beta_users.update_all(beta_email_communication: true)
      puts "Updated #{ beta_users_count } users to receive emails for beta tests."
    end

    desc "Reset user sign_in_count"
    task reset_sign_in_count: :environment do
      user_logins = ENV['USERS'].try(:split, ",")
      query = User.where(migrated: true).where("sign_in_count > 1")
      if user_logins
        query = query.where(User.arel_table[:login].lower.in(user_logins.map(&:downcase)))
      end
      query.update_all(sign_in_count: 0)
    end

    desc "Set unsubscribe tokens for individual users"
    task setup_unsubscribe_token: :environment do
      unsubscribe_token_scope = User.where(unsubscribe_token: nil)
      missing_token_count = unsubscribe_token_scope.count
      unsubscribe_token_scope.find_each.with_index do |user, index|
        puts "#{ index } / #{ missing_token_count }" if index % 1_000 == 0
        if login = user.login
          token = UserUnsubscribeMessageVerifier.create_access_token(login)
          user.update_column(:unsubscribe_token, token)
        end
      end
      puts "Updated #{ missing_token_count } users have unsubscribe tokens."
    end

    desc "Create project preferences for projects classified on"
    task create_project_preferences: :environment do
      project = Project.find(ENV["PROJECT_ID"])

      if user = User.find_by(id: ENV["USER_ID"])
        p "Updating: #{user.login}"
        UserProjectPreference.create!(user: user, project: project)
      else
        query = User.joins(:classifications)
                .where(classifications: {project_id: project.id})
                .where.not(id: UserProjectPreference.where(project: project).select(:user_id))
                .distinct
        total = query.count
        query.find_each.with_index do |user, i|
          p "Updating: #{i+1} of #{total}"
          UserProjectPreference.create!(user: user, project: project)
        end
      end
    end

    desc "Sync user login/display_name with identity_group"
    task sync_logins: :environment do
      query = User.joins(:identity_group).where('"user_groups"."name" != "users"."login" OR "user_groups"."display_name" != "users"."display_name"')
      total = query.count
      query.find_each.with_index do |user, i|
        puts "Updating #{ i+1 } of #{total}"
        ig = user.identity_group
        ig.name = user.login
        ig.display_name = user.display_name
        ig.save(validate: false)
      end
    end

    desc "Set default value for whitelist upload count"
    task :upload_whitelist_default => :environment do
      User.where(upload_whitelist: nil).select("id").find_in_batches do |batch|
        User.where(id: batch.map(&:id)).update_all(upload_whitelist: false)
        print '.'
      end
      puts ' done'
    end
  end

  namespace :slug do
    desc "regenerate slugs"
    task regenerate: :environment do
      Project.find_each(&:save!)

      Collection.find_each(&:save!)
    end
  end

  namespace :recent do
    desc "Create missing recents from classifications"
    task create_missing_recents: :environment do
      query = Classification
              .joins("LEFT OUTER JOIN recents ON recents.classification_id = classifications.id")
              .where('recents.id IS NULL')
      total = query.count
      query.find_each.with_index do |classification, i|
        puts "#{i+1} of #{total}"
        Recent.create_from_classification(classification)
      end
    end

    desc "Remove all recents that have no traceable user in the classification"
    task remove_no_user_recents: :environment do
      no_user_recents = Recent.where(user_id: nil)
        .joins(:classification)
        .where(classifications: { user_id: nil })
        .select(:id)

      no_user_recents.find_in_batches.with_index do |batch, batch_index|
        puts "Processing relation ##{batch_index}"
        Recent.where(id: batch.map(&:id)).delete_all
      end
    end

    desc "Backfill belongs_to relations from classifications"
    task backfill_belongs_to_relations: :environment do
      scope = Recent.where(user_id: nil)
        .includes(:classification)
        .where.not(classifications: { user_id: nil })
        .preload(:subject)
      total = scope.count
      scope.find_each.with_index do |recent, i|
        # some recents are for non-logged in classifications
        next if recent.user_id || recent.classification.user_id.nil?
        puts "#{i+1} of #{total}"
        recent.send(:copy_classification_fkeys)
        recent.save!(validate: false) if recent.changed?
      end
    end
  end

  namespace :classification do
    desc "Add lifecycled at timestamps"
    task add_lifecycled_at: :environment do
      non_lifecycled = Classification.where(lifecycled_at: nil).select('id')
      non_lifecycled.find_in_batches do |classifications|
        Classification.where(id: classifications.map(&:id))
        .update_all(lifecycled_at: Time.current.to_s(:db))
      end
    end

    desc "Convert non-standard Wildcam survey annotations"
    task wildcam_annotations: :environment do
      Classification.where(workflow_id: 338).find_each do |classification|
        next if classification.metadata["converted_legacy_survey_format"]

        new_annotations = classification.annotations.map do |annotation|
          if annotation["task"] == "survey"
            annotation.merge("task" => "T1", "value" => Array.wrap(annotation["value"]))
          else
            annotation
          end
        end

        new_metadata = classification.metadata.merge("converted_legacy_survey_format" => true)

        classification.update_columns annotations: new_annotations, metadata: new_metadata
      end
    end

    desc "Migrate gold standard classifiations to their own model"
    task migrate_gold_standard_to_own_model: :environment do
      non_migrated_gs_scope = Classification
        .gold_standard
        .joins("LEFT OUTER JOIN gold_standard_annotations ON gold_standard_annotations.classification_id = classifications.id")
        .where('gold_standard_annotations.id IS NULL')

      to_migrate_count = non_migrated_gs_scope.count
      failed_ids = []
      migrated_ids = []

      non_migrated_gs_scope.find_each.with_index do |classification, index|
        curr_index = index + 1
        if (curr_index % 10).zero? || curr_index == to_migrate_count
          puts "Migrating classification to gold standard: #{curr_index} / #{to_migrate_count}"
        end

        begin
          GoldStandardAnnotation.create!(classification: classification) do |gsa|
            gsa.project_id = classification.project_id
            gsa.workflow_id = classification.workflow_id
            gsa.subject_id = classification.subjects.first.id
            gsa.user_id = classification.user_id
            gsa.annotations = classification.annotations
            gsa.metadata = classification.metadata
          end
          migrated_ids << classification.id
        rescue ActiveRecord::RecordInvalid => e
          failed_ids << classification.id
        end
      end
      puts "Successfully migrated #{migrated_ids.count}"
      puts "Failed to migrate #{failed_ids.count}"
      puts "Failed classification ids #{failed_ids.join(",")}"
    end
  end

  namespace :tutorial do
    desc "Associate all workflows with tutorials"
    task :workflowize => :environment do
      Tutorial.find_each do |tutorial|
        tutorial.workflows = tutorial.project.workflows.where(active: true)
        tutorial.save!
        print '.'
      end
    end
  end

  namespace :project_page do
    desc "Rename Project page result keys"
    task :rename_result_pages => :environment do
      result_pages = ProjectPage.where(url_key: 'result', title: 'Result')
      result_pages.update_all(url_key: 'results', title: 'Results')
    end
  end

  namespace :subjects do
    desc "Set default value for subject activated_state"
    task :activated_state_default => :environment do
      scope = Subject.unscoped
      subjects = scope.where(activated_state: nil).select(:id)
      subjects.find_in_batches do |batch|
        scope.where(id: batch.map(&:id)).update_all(activated_state: 0)
        print '.'
      end
      puts ' done'
    end
  end

  namespace :workflows do
    desc "Set the workflows version cache key attribute"
    task :update_version_cache_key => :environment do
      Workflow.where(current_version_number: nil).find_each do |w|
        w.send(:update_workflow_version_cache)
      end
    end

    desc "Backfill new style of version numbers from Papertrail versions"
    task :backfill_major_minor_versions => :environment do
      Workflow.find_each do |workflow|
        workflow.update! major_version: workflow.current_version_number.to_i,
                         minor_version: workflow.primary_content.current_version_number.to_i
      end
    end

    desc "Backfill new real_set_member_subjects_count values for cached subjects_count"
    task :backfill_real_set_member_subjects => :environment do
      non_backfilled_scope = Workflow.where(real_set_member_subjects_count: 0)
      non_backfilled_scope.find_each do |workflow|
        counter = WorkflowCounter.new(workflow)
        workflow.update!(real_set_member_subjects_count: counter.subjects)
      end
    end
  end

  namespace :media do
    # Media resources id 1 - 457799 are all subjects for project Snapshot Supernova.
    # They currently exist outside of our media folder organizational structure.
    # All files have already been copied over to /subject_location, this task must be run
    # to update the media record src (which points to where the file is located)
    desc 'Update src to subject_locations for Snapshot Supernova media'
    task rewrite_supernova_file_locations: :environment do
      # this will return match data that will give us just the file name,
      # which is the part of the string following the old path
      OLD_PATH_REGEX = /\A(panoptes-uploads.zooniverse.org\/1\/0\/)?(.+)\z/.freeze

      puts 'starting supernova src location rewrite'
      Media.where('id <= 457799').find_each.with_index do |medium, index|
        matches = OLD_PATH_REGEX.match(medium.src)
        # array index 1 will be nil if src does not start with panoptes-uploads.../0/
        if matches[1]
          # array index 2 is the second capture group (anything after panoptes-uploads.../0/)
          file_name = matches[2]
          new_path = 'subject_location/' + file_name
          medium.update_column(:src, new_path)
        end
        puts "progress: #{index} records processed" if index % 1000.zero?
      end
      puts 'finished supernova src location rewrite'
    end
  end

  namespace :subject_workflow_status do
    desc "Create SubjectWorklfowStatus records for the internal PG subject selector"
    task :create_records_for_pg_selector => :environment do
      Workflow.active.select(%i(id project_id)).find_each do |workflow|
        project_finished = Project.where(id: workflow.project_id).finished.exists?
        next if project_finished

        linked_workflow_sets = workflow
          .subject_sets_workflows
          .select(%i(id subject_set_id))
        linked_workflow_sets.find_each do |subject_set_workflow|
          SubjectSetStatusesCreateWorker.perform_async(
            subject_set_workflow.subject_set_id,
            workflow.id
          )
        end
      end
    end
  end

  namespace :user_seen_subjects do
    desc "Merge USS for the same user/workflow"
    task :merge_duplicates => :environment do
      UserSeenSubject.select("user_id, workflow_id").group("user_id, workflow_id").having("COUNT(*) > 1").each do |duplicate|
        user_seen_subjects = UserSeenSubject.where(user_id: duplicate.user_id, workflow_id: duplicate.workflow_id)
        target = user_seen_subjects[0]
        dupes = user_seen_subjects[1..-1]

        dupes.each do |dupe|
          UserSeenSubject.transaction do
            UserSeenSubject.where(id: target.id)
              .update_all(["subject_ids = uniq(subject_ids + array[?])", dupe.subject_ids])
            dupe.destroy
          end
        end
      end
    end
  end

  namespace :contents do
    desc "Copy org contents to orgs"
    task :copy_org_contents => :environment do
      Organization.find_each do |org|
        content = org.primary_content
        org.title = content.title
        org.description = content.description
        org.introduction = content.introduction
        org.url_labels = content.url_labels
        org.announcement = content.announcement
        org.save!(validate: false)
      end
    end

    desc "Copy workflow contents to orgs"
    task :copy_workflow_contents => :environment do
      Workflow.find_each do |workflow|
        content = workflow.primary_content
        workflow.strings = content.strings
        workflow.save!(validate: false)
      end
    end

    desc "Copy project contents to projects"
    task :copy_project_contents => :environment do
      Project.find_each do |project|
        content = project.primary_content
        project.description = content.description
        project.introduction = content.introduction
        project.url_labels = content.url_labels
        project.workflow_description = content.workflow_description
        project.researcher_quote = content.researcher_quote
        project.save!(validate: false)
      end
    end

    desc 'backfill workflow versions for those workflows that have none'
    task :backfill_missing_workflow_versions => :environment do
      Workflow.find_each do |workflow|
        if workflow.workflow_versions.count == 0
          workflow.build_version.save!
        end
      end
    end

    desc "Backfill org page versions"
    task :backfill_organization_page_versions => :environment do
      OrganizationPage.find_each do |org_page|
        OrganizationPage.transaction do
          org_page.organization_page_versions.delete_all
          org_page.versions[1..-1].each do |version|
            reified = version.reify
            OrganizationPageVersion.create! \
              organization_page_id: org_page.id,
              title: reified.title,
              content: reified.content,
              url_key: reified.url_key,
              created_at: reified.created_at,
              updated_at: reified.updated_at
          end

          OrganizationPageVersion.create! \
            organization_page_id: org_page.id,
            title: org_page.title,
            content: org_page.content,
            url_key: org_page.url_key,
            created_at: org_page.created_at,
            updated_at: org_page.updated_at
        end
      end
    end

    desc "Backfill project page versions"
    task :backfill_project_page_versions => :environment do
      ProjectPage.find_each do |project_page|
        ProjectPage.transaction do
          project_page.project_page_versions.delete_all
          project_page.versions[1..-1].each do |version|
            reified = version.reify
            ProjectPageVersion.create! \
              project_page_id: project_page.id,
              title: reified.title,
              content: reified.content,
              url_key: reified.url_key,
              created_at: reified.created_at,
              updated_at: reified.updated_at
          end

          ProjectPageVersion.create! \
            project_page_id: project_page.id,
            title: project_page.title,
            content: project_page.content,
            url_key: project_page.url_key,
            created_at: project_page.created_at,
            updated_at: project_page.updated_at
        end
      end
    end
  end
end
