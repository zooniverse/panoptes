module RoleControl
  class RoleQuery
    def initialize(roles, public, resource_class)
      @roles, @public, @klass = roles, public, resource_class
    end

    def build(actor, target=nil)
      binding, join_query = join_clause(actor, target)
      
      query = @klass.where(where_clause(!!join_query))
      query = query.joins(join_query) if join_query
      
      rebind(query, binding)
    end

    private

    def rebind(query, bindings)
      return query unless bindings
      bindings.try(:reduce, query) { |q, b| q.bind(b) } 
    end

    def table
      @klass.arel_table
    end
    
    def roles_table
      @roles_table ||= Arel::Table.new(:roles_query)
    end

    def role_query(actor, target)
      target = target.nil? ? @klass : target
      q = actor.roles_query(target)
      binding, arel = q.try(:bind_values), q.try(:arel).try(:as, 'roles_query')
      [binding, arel]
    end

    def join_clause(actor, target)
      binding, query = role_query(actor, target)
      query = table.create_join(query, join_on, Arel::Nodes::OuterJoin) if query
      [binding, query]
    end
    
    def join_on
      table.create_on(roles_table[join_id].eq(table[:id]))
    end

    def join_id
      "#{ @klass.model_name.singular }_id".to_sym
    end

    def where_clause(include_roles)
      if include_roles && @public
        roles_test.or(public_test)
      elsif @public
        public_test
      elsif include_roes
        roles_test
      end
    end

    def public_test
      table[@roles].eq('{}')
    end

    def roles_test
      test = roles_table[:roles].not_eq(nil)
        .and(roles)

      Arel::Nodes::Grouping.new(test)
    end

    def roles
      if @roles.is_a?(Array)
        roles_table[:roles].overlap(@roles)
      else
        roles_table[:roles].overlap(table[@roles])
      end
    end
  end
end

