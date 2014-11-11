module JsonApiController
  module CreatableResource
    include RelationManager

    def create
      resource = ActiveRecord::Base.transaction do
        resource = build_resource_for_create(create_params)
        resource.save!
        resource
      end

      created_resource_response(resource) if resource.persisted?
    end

    protected

    def owner
      owner_from_params || api_user.user
    end

    def build_resource_for_create(create_params)
      link_params = create_params.delete(:links)
      if block_given?
        yield create_params, link_params
      end
      @controlled_resource = resource_class.new(create_params)
      link_params.try(:each) { |k,v| update_relation(k,v) }
      controlled_resource
    end

    def create_response(resource)
      serializer.resource(resource, nil, context)
    end

    def link_header(resource)
      send(:"api_#{ resource_name }_url", resource)
    end
  end
end
