class TranslationStrings
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end

  def extract
    resource_attributes.slice(*translatable_attributes)
  end

  private

  # def visitor_extract_strings
  #   if content_model_resource?
  #     attrs
  #   else
  #     # this doesn't seem to be used in pandora
  #     # looks like pandora will iterate over the list of
  #     # translated resources and extract the attributes in visit_question
  #     visitor = TasksVisitors::ExtractStrings.new
  #     stripped_items = visitor.visit(attrs[*translatable_attributes])
  #     extracted_strings = visitor.collector
  #   end
  # end
  #
  # CONTENT_MODELS = %w(project workflow).freeze
  # def content_model_resource?
  #   CONTENT_MODELS.include?(resource.model_name.singular)
  # end

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
    %i(display_name title description workflow_description introduction researcher_quote url_labels)
  end

  def workflow_attributes
    %i(display_name strings)
  end

  def tutorial_attributes
    raise NotImplementedError.new("Tutorial")
  end

  def field_guide_attributes
    %i(items)
  end

  def project_page_attributes
    raise NotImplementedError.new("ProjectPage")
  end

  def organization_attributes
    raise NotImplementedError.new("Org")
  end

  def organization_page_attributes
    %i(title content)
  end
end
