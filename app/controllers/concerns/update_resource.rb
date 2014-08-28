module UpdateResource
  extend ActiveSupport::Concern
  
  def update
    attributes = request_update_attributes(controlled_resource)
    controlled_resource.update!(attributes)
    response = resource_serializer(controlled_resource)
    render json_api: response
  end

  def request_update_attributes(resource)
    if request.patch?
      # Currently Unsupported
      accessible_attributes = resource.class.accessible_attributes.to_a
      patched_attributes = patch_resource_attributes(request.body.read, resource.to_json)
      patched_attributes.slice(*accessible_attributes)
    else
      permitted_update_attributes
    end
  end

  def patch_resource_attributes(json_patch_body, resource_json_doc)
    patched_resource_string = JSON.patch(resource_json_doc, json_patch_body)
    JSON.parse(patched_resource_string)
  rescue JSON::PatchError
    raise Api::PatchResourceError.new("Patch failed to apply, check patch options.")
  end
end
