module RoleControl
  class UnrolledUser
    class EmptyRoles 
      def roles
        []
      end
    end

    def self.roles_query_for(*args)
      [EmptyRoles.new]
    end

    def roles_query_for(*args)
      self.class.roles_query_for
    end
  end
end
