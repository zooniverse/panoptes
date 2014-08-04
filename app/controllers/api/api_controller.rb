module Api
  class PanoptesApiError < StandardError; end
  class PatchResourceError < PanoptesApiError; end
  class UnauthorizedTokenError < PanoptesApiError; end
  class UnsupportedMediaType < PanoptesApiError; end
  class UserSeenSubjectIdError < PanoptesApiError; end

  class ApiController < ApplicationController
    include JSONApiRender

    API_ACCEPTED_CONTENT_TYPE = 'application/json'
    API_ALLOWED_METHOD_OVERRIDES = { 'PATCH' => 'application/patch+json' }

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_record
    rescue_from Api::UnauthorizedTokenError, with: :not_authenticated
    rescue_from Api::UnsupportedMediaType, with: :unsupported_media_type
    rescue_from Api::UserSeenSubjectIdError, with: :unprocessable_entity
    rescue_from ControlControl::AccessDenied, with: :not_authorized

    before_action ContentTypeFilter.new(API_ACCEPTED_CONTENT_TYPE, API_ALLOWED_METHOD_OVERRIDES)

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

    def api_user
      @api_user ||= @current_resource_owner || RoleControl::UnrolledUser.new
    end

    def current_languages
      param_langs  = [ params[:language] ]
      user_langs   = user_accept_languages
      header_langs = parse_http_accept_languages
      ( param_langs | user_langs | header_langs ).compact
    end

    alias_method :user_for_paper_trail, :current_resource_owner

    protected

    def json_api_render(status, content, location=nil)
      render status: status, json_api: content, location: location
    end

    def user_accept_languages
      api_user.try(:languages) || []
    end

    def parse_http_accept_languages
      language_extractor = AcceptLanguageExtractor.new(request.env['HTTP_ACCEPT_LANGUAGE'])
      language_extractor.parse_languages
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

    def unprocessable_entity(exception)
      json_api_render(:unprocessable_entity, exception)
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

    def owner_from_params
      OwnerName.where(name: params[:owner]).first.try(:resource)
    end

    private

    def revoke_doorkeeper_request_token!
      token = Doorkeeper.authenticate(request)
      token.revoke
    end
  end
end
