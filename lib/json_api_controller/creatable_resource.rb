module JsonApiController
  module CreatableResource
    include RelationManager
    
    def create
      resource = ActiveRecord::Base.transaction do 
        create_resource(create_params)
      end
      created_resource_response(resource) if resource.save!
    end

    protected
    
    def owner
      owner_from_params || api_user.user
    end
    
    def create_resource(create_params)
      link_params = create_params.delete(:links)
      @controlled_resource = resource_class.new(create_params)
      
      link_params.try(:each) do |k,v|
        update_relation(k,v)
      end

      controlled_resource
    end

    def create_response(resource)
      serializer.resource(resource)
    end

    def link_header(resource)
      send(:"api_#{ resource_name }_url", resource)
    end
  end
end
