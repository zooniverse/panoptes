class TutorialUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A Tutorial Resource"
    additional_properties false

    property "display_name" do
      type "string"
    end

    property "steps" do
      type "array"
      items do
        type "object"
        additional_properties false

        property "media" do
          type "string"
        end

        property "content" do
          type "string"
        end
      end
    end

    property "configuration" do
      type "object"
    end
  end
end
