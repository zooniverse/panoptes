class UniqueRoutableName

  class DuplicateRoutableNameError < StandardError; end

  class << self

    def unique?(name, resource_id, resource_class)
      return false if name.blank?
      @name, @resource_id, @resource_class = name, resource_id, resource_class
      uniq_user_and_group_sql = "SELECT 'user', id, login FROM users " +
                                "WHERE login iLIKE '#{name}' " +
                                "UNION ALL " +
                                "SELECT 'user_group', id, display_name FROM user_groups " +
                                "WHERE display_name iLIKE '#{name}'"
#TODO: get the iLike to use an index
      rows = ActiveRecord::Base.connection.select_rows(uniq_user_and_group_sql).map(&:compact)
      check_name_is_unique(rows)
    end

    def check_name_is_unique(rows)
      case rows.length
      when 0
        true
      when 1
        row_data = rows.first
        if @resource_class.match(/#{row_data[0]}/i) && @resource_id == row_data[1]
          true
        else
          false
        end
      else
        raise DuplicateRoutableNameError.new("More than one user / user_group with the same unique name: '#{@name}'")
      end
    end
  end
end
