class OrganizationCreateSchema < JsonSchema
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

    property "announcement" do
       type "string"
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

    property "categories" do
      type "array"
      items do
        type "string"
      end
    end

    property "tags" do
      type "array"
      items do
        type "string"
      end
    end
  end
end
