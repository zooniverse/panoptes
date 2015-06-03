class ClassificationUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A Classification"
    required "annotations"
    additional_properties false

    property "completed" do
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
  end
end
