module RoleControl
  module UnrolledUser
    extend ActiveSupport::Concern
    
    class EmptyRoles 
      def roles
        []
      end
    end

    module ClassMethods
      def roles_query(*args)
        [EmptyRoles.new]
      end
    end

    def roles_query(*args)
      self.class.roles_query
    end

    def roles_for
      nil
    end
  end
end
