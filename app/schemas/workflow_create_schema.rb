class WorkflowCreateSchema < JsonSchema
  schema do
    type "object"
    description "A Description of a Classification Workflow"
    required "primary_language", "display_name", "links"

    additional_properties false

    property "primary_language" do
      type "string"
    end

    property "pairwise" do
      type "boolean"
    end

    property "grouped" do
      type "boolean"
    end

    property "active" do
      type "boolean"
    end

    property "public_gold_standard" do
      type "boolean"
    end

    property "retirement" do
      type "object"
      additional_properties false

      property "criteria" do
        type "string"
      end

      property "options" do
        type "object"
      end
    end

    property "display_order_position" do
      type "integer"
    end

    property "prioritized" do
      type "boolean"
    end

    property "display_name" do
      type "string"
    end

    property "first_task" do
      type "string"
    end

    property "tasks" do
      type "object"
    end

    property "aggregation" do
      type "object"
    end

    property "configuration" do
      type "object"
    end

    property "links" do
      type "object"
      required "project"
      additional_properties false

      property "project" do
        type "string", "integer"
      end

      property "tutorial_subject" do
        type "string", "integer"
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
