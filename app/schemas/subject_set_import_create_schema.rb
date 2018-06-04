class SubjectSetImportCreateSchema < JsonSchema
  schema do
    type "object"
    description "An import of external subjects into Panoptes"
    required "links"
    additional_properties false

    property "source_url" do
      type "string"
    end

    property "links" do
      type "object"
      additional_properties false

      required "subject_set"

      property "subject_set" do
        type "integer", "string"
      end
    end
  end
end

