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
        type ""
      end

      property "finished_at" do
        type ""
      end

      property "user_language" do
      end

      property "workflow_version" do
        type ""
      end

      property "user_agent" do
        type ""
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
      end

      property "workflow" do
        type "string", "integer"
      end

      property "set_member_subjects" do
        type "array"
        items do
          type "string", "integer"
        end
      end
      
      property "subjects" do
        type "array"
        items do
          type "string", "integer"
        end
      end
    end
  end
end
