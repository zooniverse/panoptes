class SubjectSetImportSerializer
  include RestPack::Serializer
  include CachedSerializer

  attributes :id, :href, :created_at, :updated_at, :source_url
  can_include :subject_set, :user

  can_filter_by :subject_set, :user
end

