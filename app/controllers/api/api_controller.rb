module Api
  include ApiErrors
  
  class ApiController < ApplicationController
    include RoleControl::RoledController
    include JSONApiRender
    include JSONApiResponses
    include UpdatableResource
    include DestructableResource
    include CreatableResource

    API_ACCEPTED_CONTENT_TYPE = 'application/json'
    API_ALLOWED_METHOD_OVERRIDES = { 'PATCH' => 'application/patch+json' }

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_record
    rescue_from Api::UnauthorizedTokenError, with: :not_authenticated
    rescue_from Api::UnsupportedMediaType, with: :unsupported_media_type
    rescue_from Api::UserSeenSubjectIdError, with: :unprocessable_entity
    rescue_from ControlControl::AccessDenied, with: :not_authorized
    rescue_from Api::PatchResourceError, with: :unprocessable_entity
    rescue_from ActionController::UnpermittedParameters, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :unprocessable_entity

    before_action ContentTypeFilter.new(API_ACCEPTED_CONTENT_TYPE,
                                        API_ALLOWED_METHOD_OVERRIDES)

    def current_resource_owner
      if doorkeeper_token
        @current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id)
      end
    end

    def api_user
      @api_user ||= ApiUser.new(current_resource_owner)
    end

    def current_languages
      param_langs  = [ params[:language] ]
      user_langs   = user_accept_languages
      header_langs = parse_http_accept_languages
      ( param_langs | user_langs | header_langs ).compact
    end

    alias_method :user_for_paper_trail, :current_resource_owner

    protected

    def user_accept_languages
      api_user.try(:languages) || []
    end

    def parse_http_accept_languages
      language_extractor = AcceptLanguageExtractor.new(request.env['HTTP_ACCEPT_LANGUAGE'])
      language_extractor.parse_languages
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
  end
end
