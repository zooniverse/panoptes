module Api
  class ApiController < ApplicationController
    include Pundit

    class PatchResourceError < StandardError; end

    def api_content
      "application/vnd.api+json; version=1"
    end

    def deleted_resource_response
      render status: 204, json: {}, content_type: api_content
    end

    def request_update_attributes(resource)
      if request.patch?
        accessible_attributes = resource.class.accessible_attributes.to_a
        patched_attributes = patch_resource_attributes(request.body.read, resource.to_json)
        patched_attributes.slice(*accessible_attributes)
      else
        model_param_key = controller_name.classify.parameterize.to_sym
        params[model_param_key]
      end
    end

    def patch_resource_attributes(json_patch_body, resource_json_doc)
      patched_resource_string = JSON.patch(resource_json_doc, json_patch_body)
      JSON.parse(patched_resource_string)
    rescue JSON::PatchError
      raise PatchResourceError.new("Error: Patch failed to apply, check patch options.")
    end

    def current_resource_owner
      @current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end
  end
end
