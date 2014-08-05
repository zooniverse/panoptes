module RoleControl
  module VisibilityControlled
    extend ActiveSupport::Concern

    included do
      can :show, :check_read_roles
    end

    module ClassMethods
      def visible_to(actor)
        where(_where_clause(actor)).joins(_join_clause(actor))
      end

      protected

      def _join_clause(actor)
        roles = _roles(actor)
        return unless roles
        arel_table.create_join(roles, _role_join_on(roles), Arel::Nodes::OuterJoin)
      end

      def _where_clause(actor)
        clause = _public_test
        clause = clause.or(_owner_test(actor)) if actor.is_a?(ControlControl::Owner)
        roles = _roles(actor)
        clause = clause.or(_roles_test(roles)) if roles
        clause
      end

      def _public_test
        arel_table[:visible_to].eq([])
      end

      def _owner_test(actor)
        arel_table[:owner_id].eq(actor.id)
        .and(arel_table[:owner_type].eq(actor.class.name))
      end

      def _roles(actor)
        actor.class.roles_query_for(actor, self).try(:arel_table)
      end

      def _roles_test(table)
        table[:roles].overlap(arel_table[:visible_to])
      end

      def _role_join_on(roles)
        arel_table.create_on(roles[_role_join_id].eq(arel_table[:id]))
      end

      def _role_join_id
        "#{ model_name.singular }_id".to_sym
      end
    end

    def check_read_roles(enrolled)
      roles = enrolled.roles_query_for(self).first.try(:roles)
      return false if roles.blank?
      return true if visible_to.empty?
      p !(Set.new(roles) & Set.new(visible_to.map(&:to_s))).empty?
      !(Set.new(roles) & Set.new(visible_to.map(&:to_s))).empty?
    end
  end
end
