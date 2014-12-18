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
      @controlled_resource = resource_class.new(create_params)
      
      link_params.try(:each) do |k,v|
        controlled_resource.send("#{k}=", update_relation(k,v))
      end
      
      controlled_resource
    end

    def create_response(resource)
      serializer.resource({}, resource_scope(resource), context)
    end

    def link_header(resource)
      send(:"api_#{ resource_name }_url", resource)
    end
  end
end
