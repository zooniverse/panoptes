module JsonApiController
  module CreatableResource
    include RelationManager
    
    def create
      resource = create_resource(create_params)
      created_resource_response(resource)
    end

    protected
    
    def owner
      owner_from_params || api_user.user
    end
    
    def create_resource(create_params)
      link_params = create_params.delete(:links)
      
      ActiveRecord::Base.transaction do 
        @controlled_resource = resource_class.new(create_params)
        link_params.try(:each) do |k,v|
          update_relation(k,v)
        end
        controlled_resource.save!
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
