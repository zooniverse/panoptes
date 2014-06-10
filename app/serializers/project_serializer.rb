class ProjectSerializer
  include RestPack::Serializer
  attributes :id, :name, :display_name, :classifications_count, :subjects_count, :created_at, :updated_at
  can_include :workflows, :subject_sets, :owner
end
