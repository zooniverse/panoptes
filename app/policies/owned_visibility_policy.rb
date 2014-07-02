class OwnedVisibilityPolicy < OwnedObjectPolicy
  class Scope < Scope
    def resolve
      if user.has_role?(:admin)
        scope.all
      else
        accessible_by_role = scope.joins(user_roles).joins(resource_roles).where visible_to_role
        accessible = @scope.publicly_visible.union accessible_by_role
        alias_name = "accessible_#{ @scope.table_name }_for_#{ user.id }"
        aliased_table = scope.arel_table.create_table_alias accessible, alias_name
        @scope.select("#{ alias_name }.*").from aliased_table
      end
    end
    
    private
    
    def user_roles
      <<-SQL
        INNER JOIN users_roles ON
        users_roles.user_id = #{ user.id }
      SQL
    end
    
    def resource_roles
      <<-SQL
        INNER JOIN roles ON
        roles.id = users_roles.role_id AND
        roles.resource_type = '#{ @scope.name }' AND
        roles.resource_id = #{ scope.table_name }.id
      SQL
    end
    
    def visible_to_role
      @scope.visibility_levels.each_pair.collect do |visibility, roles|
        next if visibility == :public
        if roles.empty?
          "(#{ scope.table_name }.visibility = '#{ visibility }')"
        else
          quoted_roles = roles.collect{ |role| "'#{ role }'" }.join ', '
          "(#{ scope.table_name }.visibility = '#{ visibility }' AND
          roles.name IN (#{ quoted_roles }))"
        end
      end.compact.join ' OR '
    end
  end
end
