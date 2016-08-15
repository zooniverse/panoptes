class SubjectWorkflowStatusSerializer
  include RestPack::Serializer

  attributes :id, :classifications_count, :retired_at,
    :retirement_reason, :updated_at, :created_at, :href

  can_include :subject, :workflow

  def self.key
    @key || self.model_class.model_name.plural.to_sym
  end
end
