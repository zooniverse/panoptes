module RoleControl
  class RoleQuery
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
end
