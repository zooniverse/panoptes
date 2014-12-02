class ProjectUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A Project"
    additional_properties false
    required "name"

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

    property "title" do
      type "string"
      description "Translatable name for the project"
    end

    property "description" do
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
      
      property "workflows" do
        type "array"
        items do
          type "string"
        end
      end

      property "subject_sets" do
        type "array"
        items do
          type "string"
        end
      end
    end
  end
end
