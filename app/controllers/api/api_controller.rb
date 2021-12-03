# frozen_string_literal: true

module Api
  include ApiErrors

  class ApiController < ApplicationController
    include JsonApiController
    include JsonApiController::CheckResourcesExist

    API_ACCEPTED_CONTENT_TYPES = ['application/json',
                                  'application/vnd.api+json']
    API_ALLOWED_METHOD_OVERRIDES = { 'PATCH' => 'application/patch+json' }

    rescue_from ActiveRecord::RecordNotFound,
      Api::NoMediaError,
      JsonApiController::AccessDenied,
      Subjects::Selector::MissingSubjectSet,
      Subjects::Selector::MissingSubjects,                 with: :not_found
    rescue_from ActiveRecord::RecordInvalid,               with: :invalid_record
    rescue_from Api::LiveProjectChanges,
                Api::ImportManifestLimitExceeded,          with: :forbidden
    rescue_from Api::NotLoggedIn,
      Api::UnauthorizedTokenError,
      Operation::Unauthenticated,                          with: :not_authenticated
    rescue_from Api::UnsupportedMediaType,                 with: :unsupported_media_type
    rescue_from JsonApiController::PreconditionNotPresent, with: :precondition_required
    rescue_from JsonApiController::PreconditionFailed,     with: :precondition_failed
    rescue_from ActiveRecord::StaleObjectError,            with: :conflict
    rescue_from Api::LimitExceeded,
      Api::Unauthorized,
      Operation::Unauthorized,                             with: :not_authorized
    rescue_from Api::PatchResourceError,
      Api::UserSeenSubjectIdError,
      ActionController::UnpermittedParameters,
      ActionController::ParameterMissing,
      Subjects::Selector::MissingParameter,
      Api::RolesExist,
      JsonSchema::ValidationError,
      JsonApiController::NotLinkable,
      JsonApiController::BadLinkParams,
      Api::NoUserError,
      Api::UnpermittedParameter,
      RestPack::Serializer::InvalidInclude,
      ActiveRecord::RecordNotUnique,
      Operation::Error,
      ActiveInteraction::InvalidInteractionError,          with: :unprocessable_entity
    rescue_from Kaminari::ZeroPerPageOperation,            with: :kaminari_zero_page
    rescue_from Api::FeatureDisabled,                      with: :service_unavailable

    prepend_before_action :require_login, only: [:create, :update, :destroy]
    prepend_before_action :ban_user, only: [:create, :update, :destroy]
    prepend_before_action ContentTypeFilter.new(*API_ACCEPTED_CONTENT_TYPES,
                                                API_ALLOWED_METHOD_OVERRIDES)

    def self.require_authentication(*actions, scopes: [])
      if actions == [:all]
        before_action -> { check_authentication(scopes) }
      else
        before_action -> { check_authentication(scopes) }, only: actions
      end
    end

    def check_authentication(scopes)
      doorkeeper_authorize!(*scopes)
    end

    def current_resource_owner
      if doorkeeper_token
        @current_resource_owner ||= User.find_by_id(doorkeeper_token.resource_owner_id)
      end
    end

    def api_user
      @api_user ||= ApiUser.new(current_resource_owner, admin: admin_flag?)
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
  end
end
