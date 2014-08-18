module RoleControl
  module RoleModel
    extend ActiveSupport::Concern
    
    module ClassMethods
      class Query
        def initialize(actor_rel, resource_rel, field, parent)
          @actor_rel, @resource_rel = actor_rel, resource_rel
          @role_field, @parent = field, parent
        end

        def build(actor=nil, resources=nil)
          query = @parent.select(*select_statement)
          query = query.where(where_actor(actor)) if actor
          query = query.where(where_resources(resources)) if !resources.blank?
          query
        end

        private

        def where_actor(actor)
          arel_table[actor_field].eq(actor.id)
        end

        def where_resources(resources)
          if resources.length == 1
            arel_table[resource_field].eq(resources.first.id)
          else
            arel_table[resource_field].in(resources.map(&:id))
          end
        end

        def actor_field
          "#{ @actor_rel.klass.model_name.singular }_id".to_sym
        end

        def resource_field
          "#{ @resource_rel.klass.model_name.singular }_id".to_sym
        end

        def select_statement
          [arel_table[@role_field].as('roles'),
           arel_table[resource_field],
           arel_table[actor_field]]
        end

        def arel_table
          @parent.arel_table
        end
      end

      def roles_for(actor, resource, field: :roles, valid_roles: [])
        @role_query = Query.new(reflect_on_association(actor),
                                reflect_on_association(resource),
                                field,
                                self)
        @roles_field = field
        @valid_roles = valid_roles
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
      
      valid = send(roles_field).all? { |role| valid_roles.include?(role) }
      errors.add(role_field, "Roles must be in #{ valid_roles.join(', ') }") unless valid
    end
  end
end
