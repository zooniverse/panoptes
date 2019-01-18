module JsonApiController
  module RelationManager
    # use this method to retrieve the updatable relation
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

    # use this method to modify the resource relations
    def add_relation(resource, relation, value)
      added_relation = update_relation(resource, relation, value)
      case value
      when Array
        resource.send(relation) << added_relation
      else
        resource.send("#{relation}=", added_relation)
      end
    end

    def destroy_relation(resource, relation, value)
      ids = value.split(',').map(&:to_i)
      resource.send(relation).delete(*ids)
    end

    protected

    def find_for_string_type(resource, type, id)
      policy = Pundit.policy!(api_user, resource)
      linkable_resources = policy.linkable_for(type)
      relation_find(id, linkable_resources)
    end

    def new_items(resource, relation, value, *args)
      policy = Pundit.policy!(api_user, resource)
      linkable_resources = policy.linkable_for(relation)
      relation_find(value, linkable_resources)
    end

    def assoc_class(relation)
      resource_class.reflect_on_association(relation).klass
    end

    def relation_find(find_arg, relation)
      relation = relation.where(id: find_arg)

      # This is a workaround for  https://github.com/rails/arel/pull/349
      if find_arg.is_a?(Array)
        relations_or_error(relation, find_arg)
      else
        relation_or_error(relation, find_arg)
      end
    end

    def relations_or_error(relations, find_arg)
      if find_arg.present? && relations.empty?
        raise_link_error(relations.klass, :plural)
      end
      relations
    end

    def relation_or_error(relation, find_arg)
      found_relation = relation.first
      if find_arg.present? && found_relation.nil?
        raise_link_error(relation.klass, :singular)
      end
      found_relation
    end

    def raise_link_error(relation_klass, error_name)
      msg = "Couldn't find linked #{relation_klass.model_name.send(error_name)} for current user"
      raise JsonApiController::NotLinkable.new(msg)
    end
  end
end
