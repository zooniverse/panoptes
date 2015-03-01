module JsonApiController
  module CreatableResource
    include RelationManager

    def create
      resources = resource_class.transaction(requires_new: true) do
        begin
          Array.wrap(create_params).map do |ps|
            resource = build_resource_for_create(ps)
            resource.save!
            resource
          end
        end
      end

      resources.each do |resource|
        yield resource if block_given?
      end

      created_resource_response(resources)
    end

    protected

    def add_user_as_linked_owner(create_params)
      unless create_params.fetch(:links, {}).has_key? :owner
        create_params[:links] ||= {}
        create_params[:links][:owner] = api_user.user
      end
    end

    def build_resource_for_create(create_params)
      link_params = create_params.delete(:links)
      if block_given?
        yield create_params, link_params
      end
      resource = resource_class.new(create_params)

      link_params.try(:each) do |k,v|
        resource.send("#{k}=", update_relation(resource, k,v))
      end

      resource
    end

    def create_response(resources)
      serializer.resource({}, resources, context)
    end

    def link_header(resource)
      send(:"api_#{ resource_name }_url", resource)
    end
  end
end
