class TranslationCreateSchema < JsonSchema
  schema do
    type "object"
    description "A resource translation"
    required "language", "strings"
    additional_properties false

    property "language" do
      type "string"
    end

    property "strings" do
      type "object"
    end
  end
end
