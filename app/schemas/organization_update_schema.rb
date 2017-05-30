class OrganizationUpdateSchema < JsonSchema
  schema do
    type "object"
    description "An Organization"
    additional_properties false

    property "display_name" do
      type "string"
      description "Human readable name for a project ie Galaxy Zoo"
    end

    property "primary_language" do
      type "string"
      description "Two character ISO 639 language code, optionally include two character ISO 3166-1 alpha-2 country code seperated by a hyphen for specific locale. ie 'en', 'zh-tw', 'es_MX'"
    end

    property "description" do
      type "string"
    end

    property "introduction" do
       type "string"
    end

    property "listed_at" do
       type "string"
    end

    property "listed" do
      type "boolean"
    end

    property "urls" do
      type "array"
      items do
        type "object"
        required "label", "url"
        property "label" do
          type "string"
        end

        property "url" do
          type "url"
        end
      end
    end

    property "links" do
      type "object"
      additional_properties false

      property "project" do
        type "string", "integer"
        pattern "^[0-9]*$"
      end
    end
  end
end
