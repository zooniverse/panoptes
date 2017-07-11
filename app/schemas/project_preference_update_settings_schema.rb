class ProjectPreferenceUpdateSettingsSchema < JsonSchema
  schema do
    type "object"
    description "A user project preference setting"
    additional_properties false

    property "project_id" do
      type "string", "integer"
      pattern "^[0-9]*$"
    end

    property "user_id" do
      type "string", "integer"
      pattern "^[0-9]*$"
    end

    property "settings" do
      type "object"
      additional_properties false

      property "workflow_id" do
        type "string", "integer"
        pattern "^[0-9]*$"
      end

      property "designator" do
        type "object"
        additional_properties true
      end
    end
  end
end
