# frozen_string_literal: true
class Api::V1::TranslationsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include PolymorphicResourceScope

  polymorphic_column :translated

  require_authentication :create, :update, :destroy, scopes: [:translation]

  resource_actions :show, :index, :create, :update

  schema_type :json_schema

  before_action :downcase_language_param, except: :create

  def create
    check_polymorphic_controller_resources

    # push these scope params into create payload to validate using the create schema
    params[:translations][:translated_type] = params[:translated_type].classify
    params[:translations][:translated_id] = params[:translated_id]

    ensure_non_primary_language_request(create_params[:language])

    super
  end

  def update
    ensure_non_primary_language_request(controlled_resource.language)

    super
  end

  def serializer
    TranslationSerializer
  end

  private

  # ensure translators can update and create translated resources
  def controlled_scope
    if %i(update create).include?(action_name.to_sym)
      :translate
    else
      super
    end
  end

  def polymorphic_klass_name
    @polymorphic_klass_name ||= params[:translated_type]
  end

  def polymorphic_ids
    super("translated")
  end

  def downcase_language_param
    params[:language] = params[:language]&.downcase
  end

  # Owners & collaborators should update the primary langauge through the lab app
  # translators should not be allowed to modify a primary language via the API
  def ensure_non_primary_language_request(language=nil)
    checker = TranslationChecker.new(
      polymorphic_controlled_resourse,
      action_name,
      language
    )

    if checker.for_primary_language?
      raise JsonApiController::AccessDenied, no_resources_error_message
    end
  end

  class TranslationChecker
    attr_reader :translated_resource, :action_name, :language

    def initialize(resource, action_name, language)
      @translated_resource = resource
      @action_name = action_name
      @language = language
    end

    def for_primary_language?
      primary_language(translated_resource) == language
    end

    private

    def primary_language(resource)
      # handle the difference between resources like projects & field guides
      if resource.respond_to?(:primary_language)
        resource.primary_language
      else
        resource.language
      end
    end
  end
end
