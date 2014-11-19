class SubjectSetCreateSchema < JsonSchema
  schema do
    type "object"
    description "A Set of Subjects"
    required "links", "name"
    additional_properties false

    property "name" do
      type "string"
    end

    property "metadata" do
      type "object"
    end

    property "links" do
      type "object"
      required "project"
      property "project" do
        type "string"
      end
      
      property "workflows" do
        type "array"
        items do
          type "string"
        end
      end

      property "subjects" do
        type "array"
        items do
          type "string"
        end
      end
    end
  end
end
