class SubjectSetUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A Set of Subjects"
    additional_properties false

    property "display_name" do
      type "string"
    end

    property "metadata" do
      type "object"
    end

    property "expert_set" do
      type "boolean"
    end

    property "links" do
      type "object"
      additional_properties false

      property "workflows" do
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
