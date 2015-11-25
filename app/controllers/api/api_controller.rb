require "accept_language_extractor"

module Api
  include ApiErrors

  class ApiController < ApplicationController
    include JsonApiController
    include RoleControl::RoledController
    include ActionController::HttpAuthentication::Basic

    API_ACCEPTED_CONTENT_TYPES = ['application/json',
                                  'application/vnd.api+json']
    API_ALLOWED_METHOD_OVERRIDES = { 'PATCH' => 'application/patch+json' }

    rescue_from ActiveRecord::RecordNotFound,
      Api::NoMediaError,
      RoleControl::AccessDenied,
      SubjectSelector::MissingSubjectQueue,
      SubjectSelector::MissingSubjectSet,
      SubjectSelector::EmptyDatabaseSelect,                with: :not_found
    rescue_from ActiveRecord::RecordInvalid,               with: :invalid_record
    rescue_from Api::LiveProjectChanges,                   with: :forbidden
    rescue_from Api::NotLoggedIn,
      Api::UnauthorizedTokenError,                         with: :not_authenticated
    rescue_from Api::UnsupportedMediaType,                 with: :unsupported_media_type
    rescue_from JsonApiController::PreconditionNotPresent, with: :precondition_required
    rescue_from JsonApiController::PreconditionFailed,     with: :precondition_failed
    rescue_from ActiveRecord::StaleObjectError,            with: :conflict
    rescue_from Api::LimitExceeded,                        with: :not_authorized
    rescue_from Api::PatchResourceError,
      Api::UserSeenSubjectIdError,
      ActionController::UnpermittedParameters,
      ActionController::ParameterMissing,
      SubjectSelector::MissingParameter,
      Api::RolesExist,
      JsonSchema::ValidationError,
      JsonApiController::NotLinkable,
      JsonApiController::BadLinkParams,
      Api::NoUserError,
      Api::UnpermittedParameter,
      RestPack::Serializer::InvalidInclude,
      ActiveRecord::RecordNotUnique, with: :unprocessable_entity

    prepend_before_action :authenticate!
    prepend_before_action :require_login, only: [:create, :update, :destroy]
    prepend_before_action :ban_user, only: [:create, :update, :destroy]
    prepend_before_action ContentTypeFilter.new(*API_ACCEPTED_CONTENT_TYPES,
                                                API_ALLOWED_METHOD_OVERRIDES)

    def self.require_authentication(*actions, scopes: [])
      @doorkeeper_scopes_per_action ||= {}
      @doorkeeper_scopes_per_action[actions.map(&:to_s)] = scopes
    end

    def self.doorkeeper_scopes_per_action
      @doorkeeper_scopes_per_action
    end

    def authenticate!
      case
      when has_basic_credentials?(request)
        authenticate_or_request_with_http_basic do |login, password|
          if user = User.admin_login_using_basic_auth(login, password)
            @current_resource_owner = user
          else
            raise Api::NotLoggedIn
          end
        end
      when doorkeeper_token
        check_doorkeeper_authentication!
        @current_resource_owner = User.find_by_id(doorkeeper_token.resource_owner_id)
      else
        check_doorkeeper_authentication!
      end
    end

    def check_doorkeeper_authentication!
      (self.class.doorkeeper_scopes_per_action || {}).each do |actions, scopes|
        if actions.empty? || actions.include?("all") || actions.include?(params[:action])
          doorkeeper_authorize!(*scopes)
        end
      end
    end

    def current_resource_owner
      @current_resource_owner
    end

    def api_user
      @api_user ||= ApiUser.new(current_resource_owner, admin: admin_flag?)
    end

    def current_languages
      param_langs  = [ params[:language] ]
      user_langs   = user_accept_languages
      header_langs = parse_http_accept_languages
      ( param_langs | user_langs | header_langs ).compact
    end

    def user_for_paper_trail
      @whodunnit_id ||= current_resource_owner.try(:id) || "UnauthenticatedUser"
    end

    def user_accept_languages
      api_user.try(:languages) || []
    end

    def parse_http_accept_languages
      language_extractor = AcceptLanguageExtractor
        .new(request.env['HTTP_ACCEPT_LANGUAGE'])

      language_extractor.parse_languages
    end

    def request_ip
      request.remote_ip
    end

    def require_login
      unless api_user.logged_in?
        raise Api::NotLoggedIn.new("You must be logged in to access this resource.")
      end
    end

    def admin_flag?
      !!params[:admin]
    end

    def ban_user
      if api_user.banned?
        case action_name
        when "update"
          head :ok
        when "create"
          head :created
        when "destroy"
          head :no_content
        end
      end
    end

    def context
      case action_name
      when "show", "index"
        { languages: current_languages }
      else
        { }
      end
    end

    private

    # Turn on paper trail for all API controllers
    def paper_trail_enabled_for_controller
      true
    end
  end
end
