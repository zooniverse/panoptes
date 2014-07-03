class UniqueRoutableName

  class DuplicateRoutableNameError < StandardError; end

  class << self

    def unique?(name)
      return false if name.blank?
      uniq_user_and_group_sql = "SELECT users.login, user_groups.display_name " +
                                "FROM users FULL OUTER JOIN user_groups " +
                                "ON users.login = user_groups.display_name " +
                                "WHERE user_groups.display_name iLIKE '#{name}' OR users.login iLIKE '#{name}'"
      result_rows = ActiveRecord::Base.connection.select_rows(uniq_user_and_group_sql).flatten.compact
      check_unique_rows(result_rows, name)
    end

    def check_unique_rows(rows, name)
      case rows.length
      when 0
        true
      when 1
        false
      else
        raise DuplicateRoutableNameError.new("More than one user / user_group with the same name: #{name}")
      end
    end
  end
end
