class RelationUpdate < RelationModify
  def update(relation, value, overwrite=true)
    send(:"update_#{ assoc_type(relation) }", relation, value, overwrite)
  end

  alias_method :update_, :nil_assoc

  def update_has_one(relation, value, overwrite)
    @resource.send(:"#{ relation }=", new_relations(relation, value))
    @resource.save
  end

  alias_method  :update_belongs_to, :update_has_one

  def update_has_many(relation, value, overwrite)
    update_array = new_relations(relation, value)
    if overwrite
      @resource.send(:"#{ relation }=", update_array)
      @resource.save
    else
      @resource.send(:"#{ relation }").concat(update_array)
    end
  end

  alias_method :update_has_and_belongs_to_many, :update_has_many
  
  def new_relations(relation, values)
    return nil if values.blank?
    assoc_class(relation).scope_for(:show, @api_user).find(values)
  end
end

