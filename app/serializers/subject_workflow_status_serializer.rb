class SubjectWorkflowStatusSerializer
  include Serialization::PanoptesRestpack
  include NoCountSerializer

  attributes :id, :classifications_count, :retired_at,
    :retirement_reason, :updated_at, :created_at, :href

  can_include :subject, :workflow

  def self.key
    @key || model_class.model_name.plural.to_sym
  end
end
