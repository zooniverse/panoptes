class UniqueRoutableName

  class DuplicateRoutableNameError < StandardError; end

  def initialize(resource)
    @resource = resource
    @name = @resource.is_a?(User) ? @resource.login : @resource.display_name
  end

  def unique?
    return false if @name.blank?
    check_name_is_unique
  end

  private

    def execute_uninqueness_query
      ActiveRecord::Base.connection.select_rows(uniq_user_and_group_sql).map(&:compact)
    end

    def uniq_user_and_group_sql
      "SELECT 'user', id, login FROM users " +
      "WHERE login iLIKE '#{@name}' " +
      "UNION ALL " +
      "SELECT 'user_group', id, display_name FROM user_groups " +
      "WHERE display_name iLIKE '#{@name}'"
    end

    def check_name_is_unique
      rows = execute_uninqueness_query
      case rows.length
      when 0
        true
      when 1
        row_data = rows.first
        different_resource?(row_data[0], row_data[1]) ? false : true
      else
        raise DuplicateRoutableNameError.new("More than one user / user_group with the same unique name: '#{@name}'")
      end
    end

    def different_resource?(result_class, result_id)
      return true if @resource.id.nil?
      class_name = @resource.class.to_s.underscore
      class_name.match(/#{result_class}/i) && @resource.id.to_s != result_id
    end
end
