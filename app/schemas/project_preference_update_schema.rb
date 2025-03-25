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

    property "settings" do
      type "object"
      additional_properties false

      property "workflow_id" do
        type "string", "integer"
        pattern "^[0-9]*$"
      end

      property 'hidden' do
        type 'boolean'
      end
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
