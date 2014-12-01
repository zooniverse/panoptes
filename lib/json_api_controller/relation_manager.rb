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
      relation_find(id) do
        type.camelize
            .constantize
            .link_to_resource(controlled_resource, current_actor)
      end
    end

    def new_items(relation, value, *args)
      relation_find(value) do
        assoc_class(relation)
          .link_to_resource(controlled_resource, current_actor, *args)
      end
    end

    def assoc_class(relation)
      resource_class.reflect_on_association(relation).klass
    end

    def relation_find(find_arg)
      relation = yield
      relation.find(find_arg)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound.new("Couldn't find resource")
    end
  end
end
