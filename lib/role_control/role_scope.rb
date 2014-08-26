module RoleControl
  class RoleScope
    def initialize(roles, public, resource_class)
      @roles, @public, @klass = roles, public, resource_class
    end

    def build(actor, target=nil, extra_tests=[])
      @actor = actor
      @target = target.nil? ? @klass : target
      @extra_tests = setup_extra_tests(extra_tests)
      @actor_roles_query = nil
      build_role_scope
    end

    private

    def build_role_scope
      query_bind_values = actor_roles_query_bind_values
      query = query_without_bind_values
      return query unless query_bind_values
      query_bind_values.reduce(query) { |query, value| query.bind(value) }
    end

    def query_without_bind_values
      if join_query = join_clause
        @klass.where(roles_where_clause).joins(join_query)
      else
        @klass.where(extra_tests_where_clause)
      end
    end

    def setup_extra_tests(extra_tests)
      if @public
        extra_tests << table[@roles].eq('{}')
      else
        extra_tests
      end
    end

    def table
      @klass.arel_table
    end

    def roles_table
      @roles_table ||= Arel::Table.new(:roles_query)
    end

    def actor_roles_query
      @actor_roles_query ||= @actor.roles_query(@target)
    end

    def actor_roles_query_bind_values
      actor_roles_query.try(:bind_values)
    end

    def actor_roles_query_arel
      arel = actor_roles_query.try(:arel)
      arel.try(:as, 'roles_query')
    end

    def join_clause
      if arel_query = actor_roles_query_arel
        table.create_join(arel_query, join_on, Arel::Nodes::OuterJoin)
      end
    end

    def join_on
      table.create_on(roles_table[join_id].eq(table[:id]))
    end

    def join_id
      "#{ @klass.model_name.singular }_id".to_sym
    end

    def construct_where_clause(query)
      @extra_tests.reduce(query) { |query, extra_test| query.or(extra_test) }
    end

    def roles_where_clause
      role_test_arel = roles_table[:roles].not_eq(nil).and(roles)
      grouped_arel = Arel::Nodes::Grouping.new(role_test_arel)
      construct_where_clause(grouped_arel)
    end

    def extra_tests_where_clause
      construct_where_clause(@extra_tests.pop)
    end

    def roles
      overlap_with = if @roles.is_a?(Array)
        "{#{@roles.join(',')}}"
      else
        table[@roles]
      end
      roles_table[:roles].overlap(overlap_with)
    end
  end
end

