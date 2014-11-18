module JsonApiController
  module CreatableOrUpdatableResource
    include CreatableResource
    
    def create
      if should_update?
        fake_update
      else
        super
      end
    end

    protected
    
    def fake_update
      unless controlled_resource.roles.empty?
        raise Api::RolesExist.new
      end
      
      resource_class.transaction do
        build_resource_for_update(create_params.except(:links))
        controlled_resource.save!
      end
      
      if controlled_resource.persisted?
        created_resource_response(controlled_resource)
      end 
    end
    
    def should_update?
      find_params = create_params[:links].symbolize_keys
      @controlled_resource = resource_class.find_by(**find_params)
      return unless @controlled_resource
      controlled_resource.send(can_create_or_update?, api_user)
    end
  end
end
