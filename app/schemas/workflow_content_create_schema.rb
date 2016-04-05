class WorkflowContentCreateSchema < JsonSchema
  schema do
    type "object"
    description "Language contents for a workflow"
    required "language", "strings", "links"

    additional_properties false

    property "language" do
      type "string"
    end

    property "strings" do
      type "object"
    end

    property "links" do
      type "object"
      required "workflow"
      additional_properties false

      property "workflow" do
        type "string", "integer"
      end
    end
  end
end
