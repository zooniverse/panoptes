class AggregationSerializer
  include RestPack::Serializer
  include BlankTypeSerializer

  attributes :id, :created_at, :updated_at, :aggregation
  can_include :workflow, :subject

  can_filter_by :workflow, :subject
end
