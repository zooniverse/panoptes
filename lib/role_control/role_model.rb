module RoleControl
  module RoleModel
    extend ActiveSupport::Concern
    
    module ClassMethods
      class Query
        def initialize(actor_rel, resource_rel, field, parent)
          @actor_rel, @resource_rel = actor_rel, resource_rel
          @role_field, @parent = field, parent
        end

        def build(actor=nil)
          query = @parent.select(select_statement)
          query = query.where(where_actor(actor)) if actor
          query
        end

        private

        def where_actor(actor)
          arel_table[actor_field].eq(actor.id)
        end

        def were_resources(resources)
          if resources.length == 1
            arel_table[resource_field].eq(resources.first.id)
          else
            arel_table[resource_field].in(resources.map(&:id))
          end
        end

        def actor_field
          "#{ @actor.klass.model_name.singular }_id".to_sym
        end

        def resource_field
          "#{ @resource.klass.model_name.singular }_id".to_sym
        end

        def select_statment
          arel_table[field].as('roles')
        end

        def arel_table
          @parent.arel_table
        end
      end

      def roles_for(actor, resource, field: :roles, valid_roles: [])
        @role_query = Query.new(reflect_on_association(actor),
                                relfect_on_association(resource),
                                field,
                                self)
        @roles_field = field
        @valid_roles = valid_roles
        validate :allowed_roles
      end

      def roles_query(actor)
        @role_query.build(actor)
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
      valid_roles = self.class.valid_roles.include?(role)
      return if valid_roles.blank?
      
      valid_roles = send(roles_field).all? { |role| valid_roles.include?(role) }
      
      unless valid_roles
        errors.add(role_field, "Roles must be in #{ valid_roles.join(', ') }")
      end
    end
  end
end
