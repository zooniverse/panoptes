module JsonApiController
  module RelationManager
    def update_relation(relation, value, replace=false)

      case value
      when Hash
        id, type = value.values_at(:id, :type)
        item = type.camelize.constantize.find(id)
        controlled_resource.send(:"#{ relation }=", item)
      when Array
        new_items = assoc_class(relation).where(id: value)
        if replace
          controlled_resource.send(:"#{ relation }=", new_items)
        else
          controlled_resource.send(relation) << new_items
        end
      when String, Integer
        new_item = assoc_class(relation).find(value)
        controlled_resource.send(:"#{ relation }=", new_item)
      else
        controlled_resource.send(:"#{ relation }=", value)
      end
    end

    def destroy_relation(relation, value)
      ids = value.split(',').map(&:to_i)
      controlled_resource.send(relation).destroy(*ids)
    end

    protected

    def assoc_class(relation)
      resource_class.reflect_on_association(relation).klass
    end
  end
end
