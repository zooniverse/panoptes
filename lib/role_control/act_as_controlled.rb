require 'role_control/controlled'

module RoleControl
  module ActAsControlled
    extend ActiveSupport::Concern
    include RoleControl::Controlled
    
    module ClassMethods
      include RoleControl::Controlled::ClassMethods
      
      def can_as_by_role(action, target: nil, roles: [])
        action = "#{ action }_as".to_sym
        if target
          can action, &target_role_test_proc(roles, target)
        else
          can_by_role action, roles
        end
      end

      protected

      def target_role_test_proc(permitted_roles, target)
        role_test = role_test_proc(permitted_roles)
        
        proc do |enrolled, target_object|
          return false unless permitted_target
          self.instance_exec(enrolled, &role_test)
        end
      end
    end

    def permitted_target(target, target_object)
      target_object == target || target_object.is_a?(target)
    end
  end
end

