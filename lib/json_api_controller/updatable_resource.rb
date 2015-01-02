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
      resource_class.transaction do
        resource_ids.zip(Array.wrap(update_params)).each do |id, update_hash|
          controlled_resources.update(id, build_update_hash(update_hash, id))
        end
      end
      
      updated_resource_response(controlled_resources)
    end

    def update_links
      check_relation
      resource = controlled_resources.first
      resource_class.transaction do
        add_relation(resource, relation, params[relation])
        resource.save!
      end

      updated_resource_response(resource)
    end

    def destroy_links
      resource = controlled_resources.first
      resource_class.transaction do
        destroy_relation(resource, relation, params[:link_ids])
      end
      deleted_resource_response
    end

    protected

    def build_update_hash(update_params, id)
      return update_params unless links = update_params.delete(:links)
      links.try(:reduce, update_params) do |params, (k, v)|
        params[k] = update_relation(resource_class.find(id), k.to_sym, v)
        params
      end
    end

    def check_relation
      if params[relation].nil?
        raise Api::BadLinkParams.new("Link relation must match body keys")
      end
    end

    def update_response(resources)
      serializer.resource({}, resource_scope(resources), context)
    end

    def relation
      params[:link_relation].to_sym
    end
  end
end
