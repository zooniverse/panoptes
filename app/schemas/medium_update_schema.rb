class MediumUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A Media File"
    additional_properties false

    property "metadata" do
      type "object"
    end
  end
end
