class SetMemberSubjectSerializer
  include Serialization::PanoptesRestpack

  attributes :id, :created_at, :updated_at, :priority, :href
  can_include :subject_set, :subject, :retired_workflows
end
