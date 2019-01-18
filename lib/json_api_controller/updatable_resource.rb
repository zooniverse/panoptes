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
        resources_with_updates = controlled_resources.zip(Array.wrap(update_params))
        resources_with_updates.map do |resource, update_hash|

          if update_links = update_params.delete(:links)
            update_links.each do |relation, value|
              update_params[relation] = update_relation(
                resource,
                relation.to_sym,
                value
              )
            end
          end

          resource.assign_attributes(build_update_hash(update_params, resource))

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

    # overridable in resource controllers
    # for custom update_params
    def build_update_hash(update_params, resource)
      update_params
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
