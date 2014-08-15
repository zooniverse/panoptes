module RoleControl
  class RoleQuery
    attr_reader :association
    
    def initialize(roles, resource_class)
      @roles, @klass = roles, resource_class
    end

    def build(actor)
      @klass.joins(join_clause(actor)).where(roles_test)
    end

    private

    def table
      @klass.arel_table
    end
    
    def roles_table
      @roles_table ||= Arel::Table.new(:roles_query)
    end

    def role_query(actor)
      actor.roles_for(@klass).arel.as(roles_table)
    end

    def join_clause(actor)
      table.create_join(role_query(actor), join_on, Arel::Nodes::OuterJoin)
    end
    
    def join_on
      table.create_on(roles_table[join_id].eq(table[:id]))
    end

    def join_id
      "#{ @klass.model_name.singular }_id".to_sym
    end

    def roles_test
      test = roles_table[:roles].not_eq(nil)
        .and(roles)

      Arel::Nodes::Grouping.new(test)
    end

    def roles
      if @roles.is_a?[Array]
        roles_table[:roles].overlap(@roles)
      else
        roles_table[:roles].overlap(table[@roles])
      end
    end
  end
end

