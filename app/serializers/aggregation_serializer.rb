class AggregationSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :href, :created_at, :updated_at, :uuid, :task_id, :status
  can_include :project, :workflow, :user

  can_sort_by :id, :workflow_id, :project_id, :status, :created_at, :updated_at

  can_filter_by :project, :workflow
end
