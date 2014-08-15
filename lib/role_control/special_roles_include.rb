module RoleControl
  class SpecialRolesInclude
    def self.include_roles(klass, special_roles)
      special_roles.each do |special|
        mod = RoleControl.const_get(special.to_s.classify)
        include(mod) unless klass < mod
      end
    end
  end
end
