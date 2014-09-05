module UpdatableResource
  def update
    controlled_resource.update!(update_params)
    response = serializer.resource(controlled_resource)
    render json_api: response
  end
end
