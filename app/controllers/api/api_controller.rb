module Api
  class ApiController < ApplicationController
    include ApiErrors

    API_ACCEPTED_CONTENT_TYPES = %w(
      application/json
      application/vnd.api+json
    ).freeze
    API_ALLOWED_METHOD_OVERRIDES = {
      'PATCH' => 'application/patch+json'
    }.freeze

    rescue_from ActiveRecord::RecordNotFound,
      NoMediaError,
      RoleControl::RoledController::AccessDenied,
      AccessDenied,
      Subjects::Selector::MissingSubjectSet,
      Subjects::Selector::MissingSubjects,        with: :not_found
    rescue_from ActiveRecord::RecordInvalid,      with: :invalid_record
    rescue_from LiveProjectChanges,
      DisabledDataExport,                         with: :forbidden
    rescue_from NotLoggedIn,
      UnauthorizedTokenError,
      Operation::Unauthenticated,                 with: :not_authenticated
    rescue_from UnsupportedMediaType,             with: :unsupported_media_type
    rescue_from PreconditionNotPresent,           with: :precondition_required
    rescue_from PreconditionFailed,               with: :precondition_failed
    rescue_from ActiveRecord::StaleObjectError,   with: :conflict
    rescue_from LimitExceeded,
      Unauthorized,
      Operation::Unauthorized,                    with: :not_authorized
    rescue_from PatchResourceError,
      UserSeenSubjectIdError,
      ActionController::UnpermittedParameters,
      ActionController::ParameterMissing,
      Subjects::Selector::MissingParameter,
      Classification::MissingParameter,
      RolesExist,
      JsonSchema::ValidationError,
      NotLinkable,
      BadLinkParams,
      NoUserError,
      UnpermittedParameter,
      RestPack::Serializer::InvalidInclude,
      ActiveRecord::RecordNotUnique,
      Operation::Error,
      ActiveInteraction::InvalidInteractionError, with: :unprocessable_entity
    rescue_from FeatureDisabled,                  with: :service_unavailable

    prepend_before_action :require_login, only: %i(create update destroy)
    prepend_before_action :ban_user, only: %i(create update destroy)
    prepend_before_action ContentTypeFilter.new(
      *API_ACCEPTED_CONTENT_TYPES,
      API_ALLOWED_METHOD_OVERRIDES
    )

    def self.require_authentication(*actions, scopes: [])
      if actions == [:all]
        before_action -> { doorkeeper_authorize!(*scopes) }
      else
        before_action -> { doorkeeper_authorize!(*scopes) }, only: actions
      end
    end

    def self.resource_actions(*actions)
      @actions = actions
      if actions.first == :default
        @actions = %i(show index create update destroy)
      end

      @actions.each do |action|
        case action
        when :show
          include JsonApiController::ShowableResource
        when :index
          include JsonApiController::IndexableResource
        when :create
          include JsonApiController::CreatableResource
        when :update
          include JsonApiController::UpdatableResource
        when :destroy
          include JsonApiController::DestructableResource
        when :deactivate
          include JsonApiController::DeactivatableResource
        when :create_or_update
          include JsonApiController::CreatableOrUpdatableResource
        end
      end
    end

    def self.extra_schema_actions(*actions)
      @extra_schema_actions = actions
    end

    def self.schema_type(type)
      case type
      when :json_schema
        include JsonApiController::JsonSchemaValidator
      when :strong_params
        include JsonApiController::StrongParamsValidator
      end
    end

    def self.resource_name
      @resource_name ||= name.match(/::([a-zA-Z]*)Controller/)[1]
                       .underscore.singularize
    end

    def current_resource_owner
      if doorkeeper_token
        @current_resource_owner ||= User.find_by_id(
          doorkeeper_token.resource_owner_id
        )
      end
    end

    def api_user
      @api_user ||= ApiUser.new(current_resource_owner, admin: admin_flag?)
    end

    def user_for_paper_trail
      @whodunnit_id ||= current_resource_owner.try(:id) || "UnauthenticatedUser"
    end

    def request_ip
      request.remote_ip
    end

    def require_login
      unless api_user.logged_in?
        raise ApiErrors::NotLoggedIn.new(
          "You must be logged in to access this resource."
        )
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

    def serializer
      @serializer ||= "#{ resource_name.camelize }Serializer".constantize
    end

    def resource_name
      self.class.resource_name
    end

    def resource_sym
      resource_name.pluralize.to_sym
    end

    def resource_class
      @resource_class ||= resource_name.camelize.constantize
    end

    def operation_class(action = action_name)
      return @operation_class if @operation_class
      klass = "#{resource_name.pluralize.camelize}::#{action.camelize}"
      @operation_class = klass.constantize
    end

    def operation
      operation_class.with(api_user: api_user)
    end

    def context
      case action_name
      when "show", "index"
        { languages: UserLanguages.new(self).ordered }
      else
        { }
      end
    end

    private

    def gen_etag(query)
      etag = combine_etags(etag: query)
      key = ActiveSupport::Cache.expand_cache_key(etag)
      %("#{Digest::MD5.hexdigest(key)}")
    end

    def resource_scope(resources)
      return resources if resources.is_a?(ActiveRecord::Relation)
      resource_class.where(id: resources.try(:id) || resources.map(&:id))
    end

    # Turn on paper trail for all API controllers
    def paper_trail_enabled_for_controller
      true
    end
  end
end
