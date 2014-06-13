module Api
  class ApiController < ApplicationController

    class PatchResourceError < StandardError; end

    def api_content
      "application/vnd.api+json; version=1"
    end

    def deleted_resource_response
      render status: 204, json: {}, content_type: api_content
    end

    def patch_resource_attributes(patch_to_apply, resource)
      patched_resource_string = JSON.patch(resource.to_json, patch_to_apply)
      JSON.parse(patched_resource_string)
    rescue JSON::PatchError
      raise PatchResourceError.new("Error: Patch failed to apply, check patch options.")
    end

    def current_resource_owner
      @current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

  end
end
