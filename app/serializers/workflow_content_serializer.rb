class WorkflowContentSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :language, :strings, :href
  can_include :workflow
end
