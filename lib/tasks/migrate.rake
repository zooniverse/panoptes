# -*- mode: ruby -*-
# vi: set ft=ruby :

namespace :migrate do
  desc "Migrate to User login field from display_name"
  task user_login_field: :environment do

    total = User.count
    validator = LoginUniquenessValidator.new

    User.find_each.with_index do |user, index|
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
