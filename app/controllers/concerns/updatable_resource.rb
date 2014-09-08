module UpdatableResource
  def update
    links = update_params.delete(:links)
    p links

    ActiveRecord::Base.transaction do 
      controlled_resource.update!(update_params)
      
      links.each do |k, v|
        update_relation(controlled_resource, k, v)
      end
    end
    
    controlled_resource.reload
    render json_api: serializer.resource(controlled_resource)
  end

  def update_links
    relation = params[:link_relation].to_sym
    allowed_relation?(relation)
    
    update_relation(controlled_resource, relation, params[relation], true)
  end

  def destroy_links
    relation = params[:link_relation].to_sym
    allowed_relation?(relation)
    
    ids = params[:link_ids].split(',').map(&:to_i)
    raise BadLinkParams.new("Nothing specified to delete") if ids.blank?

    ids = (ids.length == 1) ? ids.first : ids
    destroy_relation(controlled_resource, relation, ids)
  end

  protected

  def update_relation(resource, relation, ids, add_rels=false)
    assoc = get_association(relation)
    relation_method = add_rels ? :"#{ relation }<<" : :"#{ relation }="
    if has_many_assoc?(assoc) && ids === Array
      new_relations = assoc.klass.scope_for(:show, api_user)
        .find(ids.map(&:to_i))
      resource.send(relation_method, new_relations)
    elsif has_one_assoc?(assoc) && ids === String
      new_relation = assoc.klass.scope_for(:show, api_user).find(ids.to_i)
      resource.send(relation_method, new_relation)
    else
      raise BadLinkParams.new("#{ relation } does not support the requested operation")
    end

    resource.save!
  end

  def destroy_relation(resource, relation, ids)
    assoc = get_association(relation)
    if has_many_assoc?(assoc) && ids === Array
      remaining = resource.send(relation).where.not(id: ids)
      resource.send(:"#{ relation }=", remaining)
    elsif has_on_assoc?(assoc) && (ids === Integer)
      if related = resource.send(relation)
        resource.send(:"#{ relation }=", nil)
      else
        raise BadLinkParams.new("There is not a #{ relation } with the requested id")
      end
    else
      raise BadLinkParams.new("#{ relation } does not support the requested operation")
    end
    
  end

  def has_many_assoc?(assoc)
    assoc.type == :has_many || assoc.type == :has_and_belongs_to_many
  end

  def has_one_assoc?(assoc)
    assoc.type == :belongs_to || assoc.type == :has_one
  end

  def get_association(relation)
    if assoc = resource_class.reflect_on_association(relation)
      return assoc
    else
      raise NoSuchRelation.new("#{ relation } does not exist for #{ resource_name }")
    end
  end

  
  def permit_all_associations
    resource_class.reflect_on_all_associations.map(&:name)
  end
end
