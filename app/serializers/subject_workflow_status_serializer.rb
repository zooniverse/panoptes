class SubjectWorkflowStatusSerializer
  include Serialization::PanoptesRestpack
  include NoCountSerializer

  attributes :id, :classifications_count, :retired_at,
    :retirement_reason, :created_at, :updated_at, :href

  can_include :subject, :workflow

  def self.key
    @key || model_class.model_name.plural.to_sym
  end
end
