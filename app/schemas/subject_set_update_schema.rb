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

    property "retirement" do
      type "object"
      additional_properties false

      property "criteria" do
        type "string"
      end

      property "options" do
        type "object"
      end
    end

    property "links" do
      type "object"
      
      property "workflow" do
        type "string", "integer"
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
