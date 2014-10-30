class WorkflowContentSerializer
  include RestPack::Serializer
  attributes :id, :language, :strings
  can_include :workflow
end
