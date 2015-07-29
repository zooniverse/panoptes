# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'csv'

namespace :migrate do

  namespace :user do

    desc "Migrate to User login field from display_name"
    task login_field: :environment do

      user_display_names = ENV['USERS'].try(:split, ",")
      validator = LoginUniquenessValidator.new

      null_login_users = User.where(login: nil)
      unless user_display_names.blank?
        display_name_scope = User.arel_table[:display_name].lower.in(user_display_names.map(&:downcase))
        null_login_users = null_login_users.where(display_name_scope)
      end

      total = null_login_users.count

      null_login_users.find_each.with_index do |user, index|
        puts "#{ index } / #{ total }" if index % 1_000 == 0
        sanitized_login = User.sanitize_login user.display_name

        user.login = sanitized_login
        counter = 0

        validator.validate user
        until user.errors[:login].empty?
          if user.errors[:login]
            user.login = "#{ sanitized_login }-#{ counter += 1 }"
          end

          user.errors[:login].clear
          validator.validate user
        end

        user.update_attribute :login, user.login
      end
    end

    desc "Migrate to User login field from display_name"
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
  end
end
