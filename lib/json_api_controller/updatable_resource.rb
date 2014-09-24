module JsonApiController
  module UpdatableResource
    include RelationManager
    
    def update
      ActiveRecord::Base.transaction do
        build_resource_for_update(update_params)
        controlled_resource.save!
      end
      
      controlled_resource.reload
      update_response
    end

    def update_links
      check_relation
      ActiveRecord::Base.transcation do
        update_relation(relation, params[relation])
        controlled_resource.save!
      end
      
      update_response
    end

    def destroy_links
      check_relation
      ActiveRecord::Base.transcation do
      destroy_relation(relation, params[:link_ids])
      end
      deleted_resource_response
    end

    protected

    def build_resource_for_update(update_params)
      links = update_params.delete(:links)
      controlled_resource.assign_attributes(update_params)
      links.try(:each) { |k, v| update_relation(k.to_sym, v, true) }
    end

    def check_relation
      if params[relation].nil?
        raise Api::BadLinkParams.new("Link relation must match body keys")
      end
    end
    
    def update_response
      render json_api: serializer.resource(controlled_resource)
    end

    def relation
      params[:link_relation].to_sym
    end
  end
end
