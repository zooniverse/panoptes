module RoleControl
  module RoleModel
    extend ActiveSupport::Concern

    module ClassMethods
      def roles_for(actor, resource, field: :roles, valid_roles: [])
        @role_query = RoleQuery.new(reflect_on_association(actor),
                                    reflect_on_association(resource),
                                    field,
                                    self)
        @roles_field = field
        @valid_roles = valid_roles.map(&:to_s)
        validate :allowed_roles
      end

      def roles_query(actor: nil, resources: nil, resource: nil)
        resources = [resource] if resource
        @role_query.build(actor, resources)
      end

      def valid_roles
        @valid_roles
      end

      def roles_field
        @roles_field
      end
    end

    def allowed_roles
      roles_field = self.class.roles_field
      valid_roles = self.class.valid_roles

      return true if valid_roles.blank?

      unless (send(roles_field) - valid_roles).empty?
        errors.add(roles_field, "Roles must be in #{ valid_roles }")
      end
    end
  end
end
