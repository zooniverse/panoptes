class FieldGuideUpdateSchema < JsonSchema
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
  end
end
