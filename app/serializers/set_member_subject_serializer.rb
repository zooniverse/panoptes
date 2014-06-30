class SetMemberSubjectSerializer
  include RestPack::Serializer
  attributes :id, :locations, :metadata, :created_at, :updated_at, :classifications_count, :state, :zooniverse_id

  can_include :subject_set

  def locations
    @model.subject.locations
  end

  def metadata
    @model.subject.metadata
  end

  def zooniverse_id
    @model.subject.zooniverse_id
  end

  def state
    @model.state.to_s
  end

  def self.key
    "subjects"
  end
end
