class TranslationStrings
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end

  def extract
    resource_attributes.slice(*translatable_attributes)
  end

  private

  def resource_attributes
    attrs = resource.attributes.dup.except(:id)
    attrs.merge(primary_content_attributes).with_indifferent_access
  end

  def primary_content_attributes
    return {} unless resource.class.respond_to?(:content_association)

    content_assocation = resource.class.content_association
    resource
      .send(content_assocation)
      .find_by(language: resource.primary_language)
      .attributes
      .dup
      .except(:id)
  end

  def translatable_attributes
    send("#{resource.model_name.singular}_attributes")
  end

  def project_attributes
    %i(title description workflow_description introduction researcher_quote url_labels)
  end

  def workflow_attributes
    raise NotImplementedError
  end

  def tutorial_attributes
    raise NotImplementedError
  end

  def field_guide_attributes
    raise NotImplementedError
  end

  def project_page_attributes
    raise NotImplementedError
  end

  def organization_attributes
    raise NotImplementedError
  end

  def organization_page_attributes
    nil
  end
end
