class AddLoginToUsers < ActiveRecord::Migration
  def up
    remove_index :users, :display_name
    add_column :users, :login, :string
    add_index  :users, :login, unique: true, case_sensitive: false
    add_index  :users, :display_name, unique: true, case_sensitive: false

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

    change_column :users, :login, :string, null: false
  end

  def down
    remove_index  :users, :display_name
    remove_column :users, :login
    add_index     :users, :display_name, unique: true, case_sensitive: false
  end
end
