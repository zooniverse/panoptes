module RoleControl
  module VisibilityControlled
    extend ActiveSupport::Concern

    included do
      can :show, :check_read_roles
    end

    module ClassMethods
      def visible_to(actor)
        role_bindings, roles = _roles(actor)
        query = where(_where_clause(actor, roles)).joins(_join_clause(roles))
        role_bindings.try(:each) do |binding|
          query.bind!(binding)
        end
        query
      end

      protected

      def _join_clause(roles)
        return unless roles
        arel_table.create_join(roles, _role_join_on, Arel::Nodes::OuterJoin)
      end
      
      def _where_clause(actor, roles)
        clause = _public_test
        clause = clause.or(_owner_test(actor)) if actor.is_a?(ControlControl::Owner)
        clause = clause.or(_roles_test) if roles
        clause
      end

      def _public_test
        arel_table[:visible_to].eq('{}')
      end

      def _owner_test(actor)
        arel_table[:owner_id].eq(actor.id)
          .and(arel_table[:owner_type].eq(actor.class.name))
      end

      def _roles(actor)
        query = actor.class.roles_query_for(actor, self)
        arel_query = query.try(:arel).try(:as, "roles_query")
        binds = query.try(:bind_values)
        return unless arel_query
        [binds, arel_query]
      end

      def _roles_table
        Arel::Table.new(:roles_query)
      end

      def _roles_test
        table = _roles_table
        Arel::Nodes::Grouping.new(table[:roles].not_eq(nil)
          .and(table[:roles].overlap(arel_table[:visible_to])))
      end

      def _role_join_on
        arel_table.create_on(_roles_table[_role_join_id].eq(arel_table[:id]))
      end

      def _role_join_id
        "#{ model_name.singular }_id".to_sym
      end
    end

    def check_read_roles(enrolled)
      roles = enrolled.roles_query_for(self).first.try(:roles)
      return true if visible_to.empty?
      return false if roles.blank?
      !(Set.new(roles) & Set.new(visible_to.map(&:to_s))).empty?
    end
  end
end
