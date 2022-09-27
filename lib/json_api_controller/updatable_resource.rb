module JsonApiController
  module UpdatableResource
    extend ActiveSupport::Concern
    include RelationManager
    include PreconditionCheck

    included do
      before_action :precondition_check, only: :update
    end

    def update
      @updated_resources = resource_class.transaction(requires_new: true) do
        resources_with_updates = controlled_resources.zip(Array.wrap(update_params.to_h))
        resources_with_updates.map do |resource, update_hash|
          resource.assign_attributes(build_update_hash(update_hash, resource))

          yield resource if block_given?

          resource.save!
          resource
        end
      end

      updated_resource_response
    end

    def update_links
      check_relation
      resource = controlled_resources.first
      resource_class.transaction(requires_new: true) do
        add_relation(resource, relation, params[relation])
        resource.save!
      end

      yield resource if block_given?

      updated_resource_response
    end

    def destroy_links
      resource = controlled_resources.first
      resource_class.transaction do
        destroy_relation(resource, relation, params[:link_ids])
      end

      yield resource if block_given?

      deleted_resource_response
    end

    protected

    def build_update_hash(update_params, resource)
      if links = update_params.delete(:links)
        links.try(:reduce, update_params) do |params, (k, v)|
          params[k] = update_relation(resource, k.to_sym, v)
          params
        end
      else
        update_params
      end
    end

    def check_relation
      if params[relation].nil?
        raise BadLinkParams.new("Link relation #{relation} must match body key")
      end
    end

    def update_response
      serializer.resource({}, controlled_resources, context)
    end

    def relation
      params[:link_relation].to_sym
    end

    def updated_resources
      @updated_resources
    end
  end
end
