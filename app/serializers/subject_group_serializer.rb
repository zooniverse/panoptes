class SubjectGroupSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :context, :key, :created_at, :updated_at

  can_include :group_subject, :subjects, :project
  preload :group_subject, :subjects, :project

  can_filter_by :key

  # override the type key on the group_subject link
  # as the association is a Subject resource type
  def self.links
    super.tap do |links|
      links['subject_groups.group_subject'][:type] = :subjects
    end
  end
end
