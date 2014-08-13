require 'control_control/resource'

module RoleControl
  module Controlled
    extend ActiveSupport::Concern

    module ClassMethods
      include ControlControl::Resource

      def can_by_role(action, *permitted_roles)
        can action, &role_test_proc(permitted_roles)
      end

      def can_create?(actor, *args)
        !actor.blank?
      end

      protected

      def role_test_proc(permitted_roles)
        proc do |enrolled|
          roles = enrolled.roles_query_for(self)
            .first.try(:roles)
          test_roles(roles, permitted_roles)
        end
      end
    end

    protected

    def test_roles(roles, permitted_roles)
      return false if roles.blank?
      !(Set.new(roles) & Set.new(permitted_roles.map(&:to_s))).empty?
    end
  end
end
