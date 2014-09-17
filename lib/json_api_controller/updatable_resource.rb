module JsonApiController
  module UpdatableResource
    include RelationManager
    
    def update
      links = update_params.delete(:links)

      ActiveRecord::Base.transaction do 
        controlled_resource.update!(update_params)
        links.each { |k, v| update_relation(k.to_sym, v, true) }
        controlled_resource.save!
      end
      
      controlled_resource.reload
      
      update_response
    end

    def update_links
      update_relation(relation, params[relation])
      controlled_resource.save!
      update_response
    end

    def destroy_links
      destroy_relation(relation, params[:link_ids])
      deleted_resource_response
    end

    protected
    
    def update_response
      render json_api: serializer.resource(controlled_resource)
    end

    def relation
      params[:link_relation].to_sym
    end
  end
end
