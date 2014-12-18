module JsonApiController
  module RelationManager
    def update_relation(relation, value)
      case value
      when Hash
        id, type = value.values_at(:id, :type)
        item = find_for_string_type(type, id)
        item
      when Array, String, Integer
        new_items(relation, value)
      else
        value
      end
    end

    def add_relation(resource, relation, value)
      case value
      when Array
        resource.send(relation).concat(new_items(relation, value))
      else
        resource.send("#{relation}=", update_relation(relation, value))
      end
    end

    def destroy_relation(relation, value)
      ids = value.split(',').map(&:to_i)
      controlled_resources.send(relation).destroy(*ids)
    end

    protected

    def find_for_string_type(type, id)
      relation_find(id) do
        type.camelize
          .singularize
          .constantize
          .link_to_resource(controlled_resource, api_user)
      end
    end

    def new_items(relation, value, *args)
      relation_find(value) do
        assoc_class(relation)
          .link_to_resource(controlled_resource, api_user, *args)
      end
    end

    def assoc_class(relation)
      resource_class.reflect_on_association(relation).klass
    end

    def relation_find(find_arg)
      relation = yield
      relation = relation.where(id: find_arg)
      relation = relation.to_a
      # a Subject trying to link to a project its not allowed to link to raises
      # a TypeError from Arel. I'm not sure what's causing that issue yet. 
      return find_arg.is_a?(Array) ? relation : relation.first unless relation.empty?
      raise ActiveRecord::RecordNotFound.new("Couldn't find resource")
    end
  end
end
