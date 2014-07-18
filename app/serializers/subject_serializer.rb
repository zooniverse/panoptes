class SubjectSerializer
  include RestPack::Serializer
  attributes :id, :metadata, :locations, :zooniverse_id, :created_at, :updated_at
  can_include :owner
end
