class TranslationStrings
  TRANSFORM_RESOURCES = %w(field_guide workflow).freeze
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end

  def extract
    extracted_attributes = resource_attributes.slice(*translatable_attributes)
    if transform_resource_attributes?
      send("transform_#{resource_name}_attributes", extracted_attributes)
    else
      extracted_attributes
    end
  end

  private

  def resource_name
    resource.model_name.singular
  end

  def transform_resource_attributes?
    TRANSFORM_RESOURCES.include?(resource_name)
  end

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
    send("#{resource_name}_attributes")
  end

  def project_attributes
    %i(display_name title description workflow_description introduction researcher_quote url_labels)
  end

  def workflow_attributes
    %i(display_name strings)
  end

  def tutorial_attributes
    %i(display_name steps)
  end

  def field_guide_attributes
    %i(items)
  end

  def project_page_attributes
    %i(title content)
  end

  def organization_attributes
    %i(display_name title description introduction url_labels)
  end

  def organization_page_attributes
    %i(title content)
  end

  # field guide item has icon attributes that should not be translated
  def transform_field_guide_attributes(attributes)
    attributes_to_slice = %i(title content)
    {"items" => []}.tap do |field_guide_attrs|
      attributes[:items].map do |item|
        field_guide_attrs["items"] << item.slice(*attributes_to_slice)
      end
    end
  end

  # pandora app uses the tasks key to find the tasks strings
  def transform_workflow_attributes(attributes)
    attributes["tasks"] = attributes.delete("strings")
    attributes
  end
end
