module UpdatableResource
  def update
    links = update_params.delete(:links)

    ActiveRecord::Base.transaction do 
      controlled_resource.update!(update_params)
      links.each { |k, v| update_relation(k.to_sym, v) }
    end
    
    controlled_resource.reload
    
    update_response
  end

  def update_links
    update_relation(relation, params[relation])
    update_response
  end

  def destroy_links
    destroy_relation(relation, params[:link_ids])
    deleted_resource_response
  end

  protected

  def update_relation(relation, value)
    @updater ||= RelationUpdate.new(controlled_resource, api_user)
    @updater.update(relation, value)
  end

  def destroy_relation(relation, value)
    RelationDestroy.new(controlled_resource, api_user)
      .destroy(relation, value)
  end

  def update_response
    render json_api: serializer.resource(controlled_resource)
  end

  def relation
    @relation ||= params[:link_relation].to_sym
  end
end
