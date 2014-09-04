module UpdatableResource
  def update
    attributes = request_update_attributes(controlled_resource)
    controlled_resource.update!(update_params)
    response = serializer.resource(controlled_resource)
    render json_api: response
  end
end
