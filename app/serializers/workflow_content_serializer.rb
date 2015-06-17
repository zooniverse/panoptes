class WorkflowContentSerializer
  include RestPack::Serializer
  attributes :id, :language, :strings, :href
  can_include :workflow
end
