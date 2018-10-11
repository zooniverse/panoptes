class WorkflowVersionSerializer
  include RestPack::Serializer
  include CachedSerializer

  attributes :id, :href, :created_at, :updated_at,
    :major_version, :minor_version, :grouped, :pairwise, :prioritized,
    :tasks, :first_task, :strings
  can_include :workflow
  can_filter_by :workflow
end
