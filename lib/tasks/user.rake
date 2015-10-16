# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :user do

  desc "Touch user updated at"
  task touch_user_record: :environment do
    User.select('id').find_in_batches do |users|
      ids = users.map(&:id)
      User.where(id: ids).update_all(updated_at: Time.current.to_s(:db))
    end
  end

  namespace :limit do

    class UpdateUserLimitArgsError < StandardError; end

    def update_user_limit_params(args)
      new_subject_limit = args[:new_subject_limit].to_i
      user_login = args[:user_login]
      if new_subject_limit == 0 || !user_login
        raise UpdateUserLimitArgsError.new
      else
        [ user_login, new_subject_limit ]
      end
    end

    def find_user_by_login(login)
      User.find_by!("lower(login) = '#{login.downcase}'")
    end

    desc "update user subject limits"
    task :update_subject_limits, [:user_login, :new_subject_limit] => [:environment] do |t, args|
      begin
        login, new_subject_limit = update_user_limit_params(args)
        user = find_user_by_login(login)
        user.update_column(:subject_limit, new_subject_limit)
        puts "Updated user: #{user.id} - #{user.login} to have new subject limit: #{user.subject_limit}"
      rescue UpdateUserLimitArgsError
        puts "You must supply a valid user login and a new subject limit integer value.\n\n"
        puts "rake user_limit:update_user_subject_limits['login', 'new_subject_limit']"
      rescue ActiveRecord::RecordNotFound
        puts "No user found matching the login: #{login}."
      end
    end

    desc "show user subject limits"
    task :show_subject_limits, [:user_login ] => [:environment] do |t, args|
      begin
        if login = args[:user_login].try(:downcase)
          user = find_user_by_login(login)
          puts "User #{user.id} - #{user.login} subject limits:"
          puts "Upload limit -> #{user.subject_limit || 'default panoptes limit'}"
          puts "Has uploaded -> #{user.uploaded_subjects_count}"
        else
          puts "You must supply a user login."
        end
      rescue ActiveRecord::RecordNotFound
        puts "No user found matching the login: #{login}."
      end
    end
  end
end
