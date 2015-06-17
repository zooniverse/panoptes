class AggregationSerializer
  include RestPack::Serializer

  attributes :id, :created_at, :updated_at, :aggregation, :href
  can_include :workflow, :subject

  can_filter_by :workflow, :subject
end
