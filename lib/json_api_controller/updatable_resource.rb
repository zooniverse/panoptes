module JsonApiController
  module UpdatableResource
    extend ActiveSupport::Concern
    include RelationManager
    include PreconditionCheck

    included do
      before_action only: :update do |controller|
        controller.precondition_check
      end
    end

    def update
      resource_class.transaction(requires_new: true) do
        controlled_resources.zip(Array.wrap(update_params)).each do |resource, update_hash|
          resource.update(build_update_hash(update_hash,resource))
          yield resource if block_given?
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

      updated_resource_response
    end

    def destroy_links
      resource = controlled_resources.first
      resource_class.transaction do
        destroy_relation(resource, relation, params[:link_ids])
      end
      deleted_resource_response
    end

    protected

    def build_update_hash(update_params, resource)
      return update_params unless links = update_params.delete(:links)
      links.try(:reduce, update_params) do |params, (k, v)|
        params[k] = update_relation(resource, k.to_sym, v)
        params
      end
    end

    def check_relation
      if params[relation].nil?
        raise Api::BadLinkParams.new("Link relation must match body keys")
      end
    end

    def update_response
      serializer.resource({}, controlled_resources, context)
    end

    def relation
      params[:link_relation].to_sym
    end
  end
end
