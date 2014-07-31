require 'control_control/resource'

module RoleControl
  module Controlled
    include ControlControl::Resource

    def can_by_role(action, *permitted_roles)
      test_proc = proc do |enrolled|
        roles = enrolled.roles_query_for(self).first.try(:roles)
        !roles.blank? &&
          !(Set.new(roles) & Set.new(permitted_roles.map(&:to_s))).empty?
      end

      can action, &test_proc
    end

    def can_create?(actor, *args)
      !actor.blank?
    end
  end
end
