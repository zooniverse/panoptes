class ClassificationCreateSchema < JsonSchema
  schema do
    type "object"
    description "A Classification"
    required "metadata", "annotations"
    additional_properties false

    property "completed" do
      type "boolean"
    end

    property "gold_standard" do
      type "boolean"
    end

    property "metadata" do
      type "object"

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

      required "project", "workflow"

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
