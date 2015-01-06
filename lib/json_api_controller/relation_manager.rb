module JsonApiController
  module RelationManager
    def update_relation(resource, relation, value)
      case value
      when Hash
        id, type = value.values_at(:id, :type)
        item = find_for_string_type(resource, type, id)
        item
      when Array, String, Integer
        new_items(resource, relation, value)
      else
        value
      end
    end

    def add_relation(resource, relation, value)
      case value
      when Array
        resource.send(relation).concat(new_items(resource, relation, value))
      else
        resource.send("#{relation}=", update_relation(resource, relation, value))
      end
    end

    def destroy_relation(resource, relation, value)
      ids = value.split(',').map(&:to_i)
      resource.send(relation).destroy(*ids)
    end

    protected

    def find_for_string_type(resource, type, id)
      relation_find(id) do
        type.camelize
          .singularize
          .constantize
          .link_to_resource(resource, api_user)
      end
    end

    def new_items(resource, relation, value, *args)
      relation_find(value) do
        assoc_class(relation)
          .link_to_resource(resource, api_user, *args)
      end
    end

    def assoc_class(relation)
      resource_class.reflect_on_association(relation).klass
    end

    def relation_find(find_arg)
      relation = yield
      relation = relation.where(id: find_arg)
      objects = relation.to_a
      # a Subject trying to link to a project its not allowed to link to raises
      # a TypeError from Arel. I'm not sure what's causing that issue yet. 
      return find_arg.is_a?(Array) ? objects : objects.first unless objects.empty?
      error_name = find_arg.is_a?(Array) ? :plural : :singular
      raise JsonApiController::NotLinkable.new("Couldn't find linked #{relation.klass.model_name.send(error_name)} for current user")
    end
  end
end
