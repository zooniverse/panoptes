class TranslationCreateSchema < JsonSchema
  schema do
    type "object"
    description "A resource translation"
    required "language", "strings", "translated_type", "translated_id"
    additional_properties false

    property "language" do
      type "string"
    end

    property "strings" do
      type "object"
    end

    property "translated_type" do
      type "string"
    end

    property "translated_id" do
      type "string", "integer"
    end
  end
end
