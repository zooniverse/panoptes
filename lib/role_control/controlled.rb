require 'control_control/resource'

module RoleControl
  module Controlled
    include ControlControl::Resource
 
    def self.included(mod)
      ControlControl::Resource.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def can_by_role(action, *permitted_roles)
        test_proc = proc do |enrolled|
          roles = enrolled.roles_query_for(self).first.roles
          !(Set.new(roles) & Set.new(permitted_roles.map(&:to_s))).empty?
        end
        
        can action, &test_proc
      end
    end
  end
end
