class Api::V1::TranslationsController < Api::ApiController
  # require_authentication :update, :destroy, scopes: [:group]
  resource_actions :show, :index, :update, :create
  schema_type :json_schema

  def translated_parental_controlled_resources
    @translated_parental_controlled_resources ||= controlled_resources
  end

  # override the controlled resources to handle the polymorphic media lookup
  # from the different routes paths, e.g. /api/workflows/:id/attached_images
  # will lookup the linked attached_images media for the workflow :id
  def translated_controlled_resources
    translation_scope = Translation.where(
      translated_id: translated_parental_controlled_resources.select(:id),
      translated_type: resource_class.name
    )
    if params.key?(:id)
     translation_scope = translation_scope.where(id: params[:id])
    end
    @controlled_resources = translation_scope
    @controlled_resource = nil
  end

  def index
    translated_parental_controlled_resources
    translated_controlled_resources
    super
  end

  def resource_name
    @resource_name ||= params[:translated_type]
  end

  # TODO: this may need to have the same treatment of before filters
  # to ensure the parent ids can cascade into the intial parental? controlled scope
  # to limit the discovery path to the correct resources
  # E.g. GET /translations?translated_type=tutorial&project_id=1
  # E.g. GET /translations?translated_type=tutorial&workflow_id=2
  def resource_ids_from_params
    if params[:translated_id]
      params[:translated_id]
    elsif params.has_key?(:id)
        params[:id]
    else
      ''
    end.split(',')
  end

  def serializer
    TranslationSerializer
  end
end
