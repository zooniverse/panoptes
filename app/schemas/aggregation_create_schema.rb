class AggregationCreateSchema < JsonSchema
  schema do
    type 'object'
    description 'An Aggregation for a workflow'
    required 'links'
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

    property 'links' do
      type 'object'
      required 'workflow'
      additional_properties false

      property 'workflow' do
        type 'integer', 'string'
        pattern '^[0-9]*$'
      end

      property 'user' do
        type 'integer', 'string'
        pattern '^[0-9]*$'
      end
    end
  end
end
