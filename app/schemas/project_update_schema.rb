class ProjectUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A Project"
    additional_properties false

    property "display_name" do
      type "string"
      description "Human readable name for a project ie Galaxy Zoo"
    end

    property "name" do
      type "string"
      description "URL string for a project downcased and underscored ie galaxy_zoo"
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

    property "launched_row_order_position" do
      type "integer"
    end

    property "beta_row_order_position" do
      type "integer"
    end

    property "redirect" do
      type "string"
    end

    property "private" do
      type "boolean"
    end

    property "live" do
      type "boolean"
    end

    property "launch_approved" do
      type "boolean"
    end

    property "beta_approved" do
      type "boolean"
    end

    property "launch_requested" do
      type "boolean"
    end

    property "beta_requested" do
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

    property "workflow_description" do
      type "string"
    end

    property "tags" do
      type "array"
      items do
        type "string"
      end
    end

   property "introduction" do
      type "string"
    end

    property "experimental_tools" do
      type "array"
      items do
        type "string"
      end
    end

    property "links" do
      type "object"
      additional_properties false

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
