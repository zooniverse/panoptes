require 'control_control/resource'

module RoleControl
  module Controlled
    extend ActiveSupport::Concern

    included do
      @roles_for = Hash.new 
    end

    module ClassMethods
      include ControlControl::Resource
      include ControlControl::ActAs

      def can_by_role(action, act_as: nil, roles: nil)
        @roles_for[action] = RoleQuery.new(roles, self)
        can action, &role_test_proc(action)
        can_as action, &role_test_proc(action) if act_as
      end

      def can_create?(actor, *args)
        !actor.blank?
      end
      
      def scope_for(action, actor)
        query = @roles_for[action].build(actor)
        actor.global_scopes(query)
      end

      protected

      def role_test_proc(action)
        proc do |enrolled|
          self.class.exists_in_scope_for(action, enrolled).exists?(self)
        end
      end
    end
  end
end
