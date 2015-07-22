class ClassificationCreateSchema < JsonSchema
  schema do
    type "object"
    description "A Classification"
    required "metadata", "annotations", "links"
    additional_properties false

    property "completed" do
      type "boolean"
    end

    property "gold_standard" do
      type "boolean"
    end

    property "metadata" do
      type "object"
      required "started_at", "finished_at", "user_agent", "user_language", "workflow_version"

      property "screen_resolution" do
        type "string"
      end

      property "started_at" do
        type "string"
      end

      property "finished_at" do
        type "string"
      end

      property "user_language" do
        type "string"
      end

      property "workflow_version" do
        type "string"
      end

      property "user_agent" do
        type "string"
      end

      property "seen_before" do
        type "boolean"
      end

      property "utc_offset" do
        type "string"
      end
    end

    property "annotations" do
      type "array"
      items do
        type "object"

        property "task" do
          type "string"
        end

        property "value" do
          type "string", "object", "array", "float", "integer"
        end
      end
    end

    property "links" do
      type "object"
      additional_properties false
      required "project", "workflow", "subjects"

      property "project" do
        type "string", "integer"
        pattern "^[0-9]*$"
      end

      property "workflow" do
        type "string", "integer"
        pattern "^[0-9]*$"
      end

      property "subjects" do
        type "array"
        items do
          type "string", "integer"
          pattern "^[0-9]*$"
        end
      end
    end
  end
end
