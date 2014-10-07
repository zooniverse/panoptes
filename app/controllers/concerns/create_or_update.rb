module CreateOrUpdate
  def create
    if should_update?
      ActiveRecord::Base.transaction do
        build_resource_for_update(create_params.except(:links))
        controlled_resource.save!
      end
      
      if controlled_resource.persisted?
        created_resource_response(controlled_resource)
      end
    else
      super
    end
  end

  private
  
  def should_update?(finder_params)
    @controlled_resource = resource_class.find_by(**finder_params)
    return unless @controlled_resource
    controlled_resource.can_update?(api_user)
  end
end
