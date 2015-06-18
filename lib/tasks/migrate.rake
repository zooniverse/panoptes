# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :migrate do
  desc "Migrate to User login field from display_name"
  task user_login_field: :environment do

    user_display_names = ENV['USERS'].try(:split, ",")

    total = User.count
    validator = LoginUniquenessValidator.new

    null_login_users = User.where(login: nil)
    unless user_display_names.blank?
      display_name_scope = User.where(display_name: user_display_names)
      null_login_users = null_login_users.merge(display_name_scope)
    end

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
end
