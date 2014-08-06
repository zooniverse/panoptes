module RoleControl
  module UnrolledUser
    extend ActiveSupport::Concern
    
    class EmptyRoles 
      def roles
        []
      end
    end

    module ClassMethods
      def roles_query_for(*args)
        [EmptyRoles.new]
      end
    end

    def roles_query_for(*args)
      self.class.roles_query_for
    end
  end
end
