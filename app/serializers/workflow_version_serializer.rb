class WorkflowVersionSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :href, :created_at, :updated_at,
    :major_number, :minor_number, :grouped, :pairwise, :prioritized,
    :tasks, :first_task, :strings

  can_include :workflow
end
