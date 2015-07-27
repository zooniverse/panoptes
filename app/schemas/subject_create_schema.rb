class SubjectCreateSchema < JsonSchema
  schema do
    type "object"
    description "A peice of media to classifiy"
    required "links", "locations"
    additional_properties false

    property "metadata" do
      type "object"
    end

    property "locations" do
      type "array"
      items do
        one_of({ "type" => "string" }, { "type" => "object" })
      end
    end

    property "links" do
      type "object"
      required "project"
      additional_properties false

      property "project" do
        type "string", "integer"
      end

      property "subject_sets" do
        type "array"
        items do
          type "string", "integer"
        end
      end

      property  "owner" do
        type "object"

        property "type" do
          type "string"
        end

        property "id" do
          type "string", "integer"
        end
      end
    end
  end
end
