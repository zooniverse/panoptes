module Api
  class ApiController < ApplicationController
    include Pundit
    include JSONApiRender

    class PatchResourceError < PanoptesControllerError; end
    class UnauthorizedTokenError < PanoptesControllerError; end

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from Pundit::NotAuthorizedError, with: :not_authorized
    rescue_from UnauthorizedTokenError, with: :not_authorized

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
      raise PatchResourceError.new("Patch failed to apply, check patch options.")
    end

    def current_resource_owner
      @current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

    def pundit_user
      current_resource_owner
    end

    protected

    def deleted_resource_response
      render status: :no_content, json_api: {}
    end

    def not_authorized(exception)
      render status: :unauthorized, json_api: exception
    end

    def not_found(exception)
      render status: :not_found, json_api: exception
    end

    def doorkeeper_unauthorized_render_options
      raise UnauthorizedTokenError.new("You don't have sufficient permissions to access this resource")
    end
  end
end
