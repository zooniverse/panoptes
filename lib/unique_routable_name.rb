class UniqueRoutableName

  class DuplicateRoutableNameError < StandardError; end

  class << self

    def unique?(name, resource_id)
      return false if name.blank?
      @name, @resource_id = name, resource_id
      uniq_user_and_group_sql = "SELECT users.id as u_id, users.login, user_groups.id as ug_id, user_groups.display_name " +
                                "FROM users FULL OUTER JOIN user_groups " +
                                "ON users.login = user_groups.display_name " +
                                "WHERE user_groups.display_name iLIKE '#{name}' OR users.login iLIKE '#{name}'"
      result = ActiveRecord::Base.connection.select_all(uniq_user_and_group_sql)
      return true if result.rows.empty?
      result_hash = result.map { |r| r }.first
      check_name_is_unique(result_hash)
    end

    def check_name_is_unique(result)
      checker = DuplicateRouteableNameChecker.new(result)
      case
      when checker.both_exist?
        raise DuplicateRoutableNameError.new("More than one user / user_group with the same unique name: '#{@name}'")
      when checker.one_exists?
        false
      when checker.none_exist?
        true
      end
    end

    class DuplicateRouteableNameChecker

      def initialize(result)
        @result = result
      end

      def both_exist?
        login_exists? && display_name_exists?
      end

      def one_exists?
        only_login_exists? ^ only_display_name_exists?
      end

      def none_exist?
        !both_exist?
      end

      private

      def only_login_exists?
        login_exists? && !display_name_exists?
      end

      def only_display_name_exists?
        display_name_exists? && !login_exists?
      end

      def login_exists?
        !!@result["login"]
      end

      def display_name_exists?
        !!@result["display_name"]
      end
    end
  end
end
