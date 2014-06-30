module Api
  class ApiController < ApplicationController
    include Pundit
    include JSONApiRender

    class PatchResourceError < PanoptesControllerError; end
    class UnauthorizedTokenError < PanoptesControllerError; end

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from Pundit::NotAuthorizedError, with: :not_authorized
    rescue_from UnauthorizedTokenError, with: :not_authenticated

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

    def current_languages
      param_langs  = [ params[:language] ]
      user_langs   = current_resource_owner.languages
      header_langs = parse_http_accept_language
      ( param_langs | user_langs | header_langs ).compact
    end

    alias_method :pundit_user, :current_resource_owner
    alias_method :user_for_paper_trail, :current_resource_owner

    protected

    def json_api_render(status, content)
      render status: status, json_api: content
    end

    def parse_http_accept_language
      request.env['HTTP_ACCEPT_LANGUAGE'].gsub(/\s+/, '').split(',').map do |lang|
        lang, priority = lang.split(";q=")
        lang = lang.downcase
        priority = priority ? priority.to_f : 1.0
        [lang, priority]
      end.sort do |(_, left), (_, right)|
        right <=> left
      end.map(&:first)
    end

    def deleted_resource_response
      json_api_render(:no_content, {})
    end

    def not_authenticated(exception)
      json_api_render(:unauthorized, exception)
    end

    def not_authorized(exception)
      json_api_render(:forbidden, exception)
    end

    def not_found(exception)
      json_api_render(:not_found, exception)
    end

    def cellect_host(workflow_id)
      host = Cellect::Client.choose_host
      current_resource_owner.cellect_hosts_will_change!
      current_resource_owner.cellect_hosts[workflow_id] = host
      current_resource_owner.save!
      host
    end
  
    private

      def revoke_doorkeeper_request_token!
        token = Doorkeeper.authenticate(request)
        token.revoke
      end
  end
end
