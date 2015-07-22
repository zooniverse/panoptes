class AggregationUpdateSchema < JsonSchema
  schema do
    type "object"
    description "An Aggregation for a subject"
    required "aggregation", "links"
    additional_properties false

    property "aggregation" do
      type "object"
    end

    property "links" do
      type "object"
      additional_properties false

      required "subject", "workflow"

      property "subject" do
        type "integer", "string"
      end

      property "workflow" do
        type "integer", "string"
      end
    end
  end
end
