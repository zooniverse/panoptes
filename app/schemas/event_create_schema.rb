class EventCreateSchema < JsonSchema
  schema do
    type "object"
    description "An Event"
    required "kind", "project_id", "zooniverse_user_id"
    additional_properties false

    property "kind" do
      type "string"
    end

    property "project_id" do
      type "string", "integer"
      pattern "^[0-9]*$"
    end

    property "zooniverse_user_id" do
      type "string", "integer"
      pattern "^.+[0-9]*$"
    end

    property "count" do
      type "string", "integer"
      pattern "^[0-9]*$"
    end

    property "project" do
      type "string"
    end

    property "workflow" do
      type "string"
    end

    property "message" do
      type "string"
    end

    property "created_at" do
      type "string"
    end
  end
end
