class SubjectGroupsSelectionSchema < JsonSchema
  schema do
    type "object"
    description "Selection params for the SubjectGroup resource"

    additional_properties false

    property 'workflow_id' do
      type 'integer'
    end

    property 'num_rows' do
      type 'integer'
    end

    property 'num_columns' do
      type 'integer'
    end
  end
end
