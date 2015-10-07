class ProjectPreferenceUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A user project preference"
    additional_properties false

    property "email_communication" do
      type "boolean"
    end

    property "preferences" do
      type "object"
    end

    property "links" do
      type "object"
      additional_properties false

      property "project" do
        type "string", "integer"
      end
    end
  end
end
