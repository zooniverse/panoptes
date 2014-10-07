module JsonApiController
  module RelationManager
    def update_relation(relation, value)
      case value
      when Hash
        id, type = value.values_at(:id, :type)
        item = find_for_string_type(type, id)
        assign(relation, item)
      when Array, String, Integer
        find_and_assign_to_resource(relation, value)
      else
        assign(relation, value)
      end
    end

    def add_relation(relation, value)
      case value
      when Array
        controlled_resource.send(relation).concat(new_items(relation, value))
      else
        update_relation(relation, value)
      end
    end

    def destroy_relation(relation, value)
      ids = value.split(',').map(&:to_i)
      controlled_resource.send(relation).destroy(*ids)
    end

    protected

    def find_and_assign_to_resource(relation, value)
      assign(relation, new_items(relation, value))
    end

    def assign(relation, items)
      controlled_resource.send(:"#{ relation }=", items)
    end

    def find_for_string_type(type, id)
      type.camelize
        .constantize
        .link_to_resource(controlled_resource, current_actor)
        .find(id)
    end

    def new_items(relation, value)
      assoc_class(relation)
        .link_to_resource(controlled_resource, current_actor)
        .find(value)
    end

    def assoc_class(relation)
      resource_class.reflect_on_association(relation).klass
    end
  end
end
