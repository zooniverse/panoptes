class WorkflowContentUpdateSchema < JsonSchema
  schema do
    type "object"
    description "Language contents for a workflow"
    required "strings"

    additional_properties false

    property "strings" do
      type "object"
    end
  end
end
