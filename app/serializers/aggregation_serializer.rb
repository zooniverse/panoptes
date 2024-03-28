class AggregationSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :href, :created_at, :updated_at, :uuid, :task_id, :status
  can_include :workflow, :user

  can_filter_by :workflow
end
