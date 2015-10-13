class TutorialCreateSchema < JsonSchema
  schema do
    type "object"
    description "A Tutorial Resource"
    additional_properties false

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
