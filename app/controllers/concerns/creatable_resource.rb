module CreatableResource
  def create
    resource = create_resource
    created_resource_response(resource)
  end

  protected
  
  def owner
    owner_from_params || api_user.user
  end
  
  def create_resource
    resource_class.create(create_params)
  end

  def create_response(resource)
    serializer.resource(resource)
  end

  def link_header(resource)
    send(:"api_#{ resource_name }_url", resource)
  end
end
