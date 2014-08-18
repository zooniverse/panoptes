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

      def can_by_role(action, act_as: nil, public: false, roles: nil)
        @roles_for[action] = RoleQuery.new(roles, public, self)
        can action, &role_test_proc(action)
        can_as action, &role_test_proc(action) if act_as
      end

      def can_create?(actor, *args)
        !actor.blank?
      end
      
      def scope_for(action, actor, target: nil, extra_test: [])
        @roles_for[action].build(actor, target, extra_test)
      end

      protected

      def role_test_proc(action)
        proc do |enrolled|
          self.class.scope_for(action, enrolled, target: self).exists?(self)
        end
      end
    end
  end
end
