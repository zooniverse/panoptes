require 'role_control/controlled'

module RoleControl
  module ActAsControlled
    include RoleControl::Controlled
    def can_as_by_role(action, target: nil, roles: [])
      action = "#{ action }_as".to_sym
      if target
        test_proc = proc do |enrolled, target_object|
          unless target_object == target || target_object.is_a?(target)
            roles = enrolled.roles_query_for(self).first.try(:roles)
            !roles.blank? &&
              !(Set.new(roles) & Set.new(permitted_roles.map(&:to_s))).empty?
          else
            false
          end
        end
        can action, &test_proc
      else
        can_by_role action, roles
      end
    end
  end
end
