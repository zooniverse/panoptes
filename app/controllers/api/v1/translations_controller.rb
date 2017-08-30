class Api::V1::TranslationsController < Api::ApiController
  require_authentication :create, :update, :destroy, scopes: [:translation]

  before_action :translated_parental_controlled_resources, only: %i(index show)
  before_action :translated_controlled_resources, only: %i(index show)
  before_action :error_unless_exists, except: :create

  # TODO: add in update action
  resource_actions :show, :index, :create

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

  def create
    translated_create_resource_scope do
      check_controller_resources
    end

    revert_resource_name_to_controller_type

    translation = Translation.transaction(requires_new: true) do
      create_params[:translated_type] = params[:translated_type].classify
      # TODO: should raise an error if this is missing
      create_params[:translated_id] = params[:translated_id]
      resource = Translation.new(create_params)
      resource.save!
      resource
    end
    created_resource_response(translation)
  end

  # check the user has the translator role on the translated resource
  def translated_create_resource_scope
    @controlled_resources = api_user.do(:translate)
    .to(resource_class, scope_context)
    .with_ids(resource_ids)
    .scope
    yield if block_given?
  end

  # override the default resource name to wire up the
  # controller authorization based on the translated_type params
  # e.g. params[:translated_type] = "Project", uses Project.scope_for(action)
  # to determine the rights of the logged in user on translation resources
  def resource_name
    @resource_name ||= params[:translated_type]
  end

  def resource_ids_from_params
    if params[:translated_id]
      params[:translated_id]
    else
      ''
    end.split(',')
  end

  def serializer
    TranslationSerializer
  end

  # re-wire the resource name based on controller name
  # once passed authorization access checks
  # these instance variables wire up the serializer responses
  # as well as the class to call scope_for authorization checks on
  def revert_resource_name_to_controller_type
    @resource_name = method(:resource_name).super_method.call
    @resource_class = resource_name.camelize.constantize
  end

  def error_unless_exists
    revert_resource_name_to_controller_type

    unless controlled_resources && controlled_resources.exists?
      rejected_message = rejected_message(params[:id])
      raise RoleControl::AccessDenied, rejected_message
    end
  end
end
