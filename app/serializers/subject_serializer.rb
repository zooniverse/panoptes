class SubjectSerializer
  include RestPack::Serializer
  attributes :id, :metadata, :locations, :zooniverse_id, :created_at, :updated_at, :owner
  can_include :owner
end
