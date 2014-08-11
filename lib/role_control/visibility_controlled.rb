module RoleControl
  module VisibilityControlled
    extend ActiveSupport::Concern

    class VisibilityQuery
      attr_reader :actor, :join_id, :parent_table, 
        :role_bindings, :roles
      
      def initialize(actor, parent, join_id)
        @actor, @parent, @join_id = actor, parent, join_id
        @parent_table = @parent.arel_table
        @role_bindings, @roles = roles_query
      end

      def build
        query = @parent.where(where_clause)
          .joins(join_clause)
        rebind(query)
        query
      end

      private
      
      def roles_table
        @roles_table ||= Arel::Table.new(:roles_query)
      end

      def rebind(query)
        role_bindings.try(:each) do |binding|
          query.bind!(binding)
        end
      end
      
      def roles_query
        query = actor.class.roles_query_for(actor, @parent)
        arel_query = query.try(:arel).try(:as, "roles_query")
        binds = query.try(:bind_values)
        return unless arel_query
        [binds, arel_query]
      end
      
      def where_clause
        clause = public_test
        
        if actor.is_a?(ControlControl::Owner)
          clause = clause.or(owner_test)
        end

        if roles
          clause = clause.or(roles_test)
        end
        
        clause
      end
      
      def join_clause
        return unless roles
        parent_table.create_join(roles, join_on, Arel::Nodes::OuterJoin)
      end
      
      def join_on
        parent_table.create_on(roles_table[join_id].eq(parent_table[:id]))
      end

      def public_test
        parent_table[:visible_to].eq('{}')
      end

      def owner_test
        parent_table[:owner_id].eq(actor.id)
          .and(parent_table[:owner_type].eq(actor.class.name))
      end


      def roles_test
        
        test = roles_table[:roles].not_eq(nil)
          .and(roles_table[:roles].overlap(parent_table[:visible_to]))

        Arel::Nodes::Grouping.new(test)
      end
    end
    

    included do
      can :show, :check_read_roles
    end

    module ClassMethods
      def visible_to(actor)
        RoleControl::VisibilityControlled::VisibilityQuery.new(actor,
                                                               self,
                                                               role_join_id)
          .build
      end
      
      protected
      
      def role_join_id
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
