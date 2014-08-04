module RoleControl
  class UnrolledUser
    class EmptyRoles 
      def roles
        []
      end
    end

    def role_query_for(target)
      [EmptyRoles.new]
    end
  end
end
