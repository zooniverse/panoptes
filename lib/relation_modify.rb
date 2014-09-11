class RelationModify
  def initialize(resource, api_user)
    @resource, @api_user = resource, api_user
  end
  
  def nil_assoc(relation, value, overwrite)
    raise Api::BadLinkParams.new("#{ relation } does not exist")
  end
  
  def assoc(relation)
    @resource.class.reflect_on_association(relation)
  end

  def assoc_type(relation)
    assoc(relation).try(:macro)
  end

  def assoc_class(relation)
    assoc(relation).try(:klass)
  end
end
