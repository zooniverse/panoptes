module Api
  class PanoptesApiError < StandardError; end
  class PatchResourceError < PanoptesApiError; end
  class UnauthorizedTokenError < PanoptesApiError; end
  class UnsupportedMediaType < PanoptesApiError; end

  class ApiController < ApplicationController
    include Pundit
    include JSONApiRender


    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_record
    rescue_from Pundit::NotAuthorizedError, with: :not_authorized
    rescue_from Api::UnauthorizedTokenError, with: :not_authenticated
    rescue_from Api::UnsupportedMediaType, with: :unsupported_media_type

    before_action ContentTypeFilter.new('application/json', 'PATCH' => 'application/patch+json')

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
      raise Api::PatchResourceError.new("Patch failed to apply, check patch options.")
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

    def json_api_render(status, content, location=nil)
      render status: status, json_api: content, location: location
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

    def invalid_record(exception)
      json_api_render(:bad_request, exception)
    end

    def unsupported_media_type(exception)
      json_api_render(:unsupported_media_type, exception)
    end

    def cellect_host(workflow_id)
      host = cellect_session[workflow_id] || Cellect::Client.choose_host
      cellect_session[workflow_id] = host
    end

    def cellect_session
      session[:cellect_hosts] ||= {}
    end


    def request_ip
      request.remote_ip
    end

    private

    def revoke_doorkeeper_request_token!
      token = Doorkeeper.authenticate(request)
      token.revoke
    end
  end
end
