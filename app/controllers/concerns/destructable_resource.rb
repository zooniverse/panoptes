module DestructableResource
  def destroy
    controlled_resource.destroy!
    deleted_resource_response
  end
end
