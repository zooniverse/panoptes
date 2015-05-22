class MediumCreateSchema < JsonSchema
  schema do
    type "object"
    description "A Media File"
    required "content_type"
    additional_properties false

    property "content_type" do
      type "string"
    end

    property "external_link" do
      type "boolean"
    end

    property "metadata" do
      type "object"
    end
  end
end
