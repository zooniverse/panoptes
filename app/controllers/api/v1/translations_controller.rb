class Api::V1::TranslationsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include PolymorphicResourceScope

  polymorphic_column :translated

  require_authentication :create, :update, :destroy, scopes: [:translation]

  # TODO: add in destroy action
  resource_actions :show, :index, :create, :update

  schema_type :json_schema

  before_action :downcase_language_param, except: :create
  before_action :non_primary_language, only: :update

  def create
    check_polymorphic_controller_resources

    translation = Translation.transaction(requires_new: true) do

      # push these scope params into create payload
      # to validate using the create schema
      params[:translations][:translated_type] = params[:translated_type].classify
      params[:translations][:translated_id] = params[:translated_id]

      resource = Translation.new(create_params)
      resource.save!
      resource
    end
    created_resource_response(translation)
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
  def non_primary_language
    translated_resource = controlled_resource.translated
    # handle the difference between resources like projects & field guides
    translated_resource_primary_language =
      if translated_resource.respond_to?(:primary_language)
        translated_resource.primary_language
      else
        translated_resource.language
      end

    if translated_resource_primary_language == controlled_resource.language
      raise JsonApiController::AccessDenied, no_resources_error_message
    end
  end
end
