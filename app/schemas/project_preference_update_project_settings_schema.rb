class ProjectPreferenceUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A user project preference"
    additional_properties false

    property "workflow_id" do
      type "string", "integer"
      pattern "^[0-9]*$"
    end

    property "project_id" do
      type "string", "integer"
      pattern "^[0-9]*$"
    end

    property "settings" do
      type "object"
    end
  end
end
