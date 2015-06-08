class WorkflowContentSerializer
  include RestPack::Serializer
  include BlankTypeSerializer
  attributes :id, :language, :strings
  can_include :workflow
end
