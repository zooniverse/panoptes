class WorkflowContentSerializer
  include RestPack::Serializer
  include CachedSerializer

  attributes :id, :language, :strings, :href
  can_include :workflow
end
