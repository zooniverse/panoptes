class AggregationUpdateSchema < JsonSchema
  schema do
    type 'object'
    description 'An Aggregation for a workflow'
    additional_properties false

    property 'uuid' do
      type 'string'
    end

    property 'task_id' do
      type 'string'
    end

    property 'status' do
      type 'string'
    end
  end
end
