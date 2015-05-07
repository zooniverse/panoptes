module JsonApiController
  extend ActiveSupport::Concern

  class BadLinkParams < StandardError; end
  class PreconditionNotPresent < StandardError; end
  class PreconditionFailed < StandardError; end
  class NotLinkable < StandardError; end

  module ClassMethods
    def resource_actions(*actions)
      @actions = actions
      if actions.first == :default
        @actions = [:show, :index, :create, :update, :destroy]
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

    def schema_type(type)
      case type
      when :json_schema
        include JsonApiController::JsonSchemaValidator
      when :strong_params
        include JsonApiController::StrongParamsValidator
      end
    end

    def resource_name
      @resource_name ||= name.match(/::([a-zA-Z]*)Controller/)[1]
                       .underscore.singularize
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

  def context
    {}
  end

  def controlled_resource
    @controlled_resource ||= controlled_resources.first
  end

  private

  def gen_etag(response_obj)
    %(#{Digest::MD5.hexdigest(response_obj.to_json)})
  end

  def resource_scope(resources)
    return resources if resources.is_a?(ActiveRecord::Relation)
    resource_class.where(id: resources.try(:id) || resources.map(&:id))
  end
end
