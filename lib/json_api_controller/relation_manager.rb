module JsonApiController
  module RelationManager
    def update_relation(relation, value, replace=false)

      case value
      when Hash
        id, type = value.values_at(:id, :type)
        item = type.camelize.constantize.find(id)
        controlled_resource.send(:"#{ relation }=", item)
      when Array
        if replace
          controlled_resource.send(:"#{ relation }=", new_items(relation, value))
        else
          controlled_resource.send(relation) << new_items(relation, value)
        end
      when String, Integer
        controlled_resource.send(:"#{ relation }=", new_items(relation, value))
      else
        controlled_resource.send(:"#{ relation }=", value)
      end
    end

    def destroy_relation(relation, value)
      ids = value.split(',').map(&:to_i)
      controlled_resource.send(relation).destroy(*ids)
    end

    protected

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
