module JsonApiController
  module DeactivatableResource
    def destroy
      Activation.disable_instances!(to_disable)
      deleted_resource_response
    end
  end
end
