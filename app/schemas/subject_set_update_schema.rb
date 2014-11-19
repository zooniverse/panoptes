class SubjectSetUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A Set of Subjects"
    additional_properties false

    property "name" do
      type "string"
    end

    property "metadata" do
      type "object"
    end

    property "links" do
      type "object"
      
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
