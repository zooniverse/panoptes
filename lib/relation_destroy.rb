class RelationDestroy < RelationModify
  def destroy(relation, value)
    send(:"destroy_#{ assoc_type(relation) }", relation, value)
  end

  alias_method :destroy_, :nil_assoc
  
  def destroy_has_one(relation, value)
    if @resouce.send(relation).id == value
      @resource.send(:"#{ relation }=", nil)
    else
      raise Api::BadLinkParams.new("Object doesn't exist in relation")
    end
    
    @resource.save
  end

  alias_method :destroy_belongs_to, :destroy_has_one

  def destroy_has_many(relation, value)
    p remaining_ids(relation, value)
    @resource.send(:"#{ relation }=", [])
    @resource.save
  end

  alias_method :destroy_has_and_belongs_to_many, :destroy_has_many
  
  def remaining_ids(relation, value)
    p value.split(',')
    @resource.send(relation).where.not(id: value.split(",").map(&:to_i)).to_a
  end
end
