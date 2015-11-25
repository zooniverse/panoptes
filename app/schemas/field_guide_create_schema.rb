class FieldGuideCreateSchema < JsonSchema
  schema do
    type "object"
    description "A Field Guide Resource"
    additional_properties false

    property "items" do
      type "array"
      items do
        type "object"
        additional_properties false

        property "icon" do
          type "string"
        end

        property "content" do
          type "string"
        end

        property "title" do
          type "string"
        end
      end
    end

    property "language" do
      type "string"
    end

    property "links" do
      type "object"
      additional_properties false

      property "project" do
        type "string"
      end
    end
  end
end
