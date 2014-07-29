require 'role_control/controlled'

module RoleControl
  module VisibilityControlled
    include RoleControl::Controlled

    def self.included(mod)
      RoleControl::Controlled.included(mod)
      mod.extend(ClassMethods)
      mod.module_eval do
        can :read, :check_read_roles
      end
    end

    module ClassMethods
      def visible_to_actor(actor)
        roles = _roles

        arel_table.join(roles, Arel::Nodes::OuterJoin)
          .on(roles[_role_join_id].eq(arel_table[:id]))
          .where(_public_test
                 .or(_owner_test(actor))
                 .or(_roles_test(roles)))
      end

      def _public_test
        table[:visible_to].eq([])
      end

      def _owner_test(actor)
        table[:owner_id].eq(actor.id)
          .and(table[:owner_type].eq(actor.class.name))
      end

      def _roles
        actor.class.roles_query_for(actor, self).arel_table
      end

      def _roles_test(table)
        table[:roles].array_overlap(arel_table[:visible_to])
      end

      def _role_join_id
        "#{ model_name.singular }_id".to_sym
      end
    end

    def check_read_roles(enrolled)
      roles = enrolled.roles_query_for(self).first_roles
      !(Set.new(roles) & Set.new(visible_to.map(&:to_s))).empty?
    end
  end
end
