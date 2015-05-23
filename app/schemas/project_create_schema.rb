class ProjectCreateSchema < JsonSchema
  schema do
    type "object"
    description "A Project"
    required "display_name", "description", "primary_language", "private"
    additional_properties false

    property "display_name" do
      type "string"
      description "Human readable name for a project ie Galaxy Zoo"
    end

    property "primary_language" do
      type "string"
      description "Two character ISO 638 language code, optionally include two character ISO 3166-1 alpha-2 country code seperated by a hyphen for specific locale. ie 'en', 'zh-tw', 'es_MX'"
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

    property "redirect" do
      type "string"
    end

    property "private" do
      type "boolean"
    end

    property "approved" do
      type "boolean"
    end

    property "beta" do
      type "boolean"
    end

    property "configuration" do
      type "object"
    end

    property "title" do
      type "string"
      description "Translatable name for the project"
    end

    property "description" do
      type "string"
    end

    property "result" do
      type "string"
    end

    property "faq" do
      type "string"
    end

    property "education_content" do
      type "string"
    end

    property "guide" do
      type "array"
      items  do
        type "object"
        required "image", "explanation"

        property "image" do
          type "string"
        end

        property "explanation" do
          type "string"
        end
      end
    end

    property "team_members" do
      type "array"
      items do
        type "object"
        required "name"

        property "name" do
          type "string"
        end

        property "bio" do
          type "string"
        end

        property "twitter" do
          type "string"
        end

        property "institution" do
          type "string"
        end
      end
    end

    property "science_case" do
      type "string"
    end

    property "introduction" do
      type "string"
    end

    property "links" do
      type "object"

      property "owner" do
        type "object"
        required "id", "type"

        property "id" do
          type "string", "integer"
        end

        property "type" do
          type "string"
        end
      end

      property "workflows" do
        type "array"
        items do
          type "string", "integer"
        end
      end

      property "subject_sets" do
        type "array"
        items do
          type "string", "integer"
        end
      end
    end
  end
end
