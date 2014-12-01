class SubjectSerializer

  include RestPack::Serializer
  attributes :id, :metadata, :locations, :zooniverse_id, :created_at, :updated_at
  can_include :owner, :versions

  def locations
    locations = @model.try(:locations).try(:dup)
    return {} unless locations
    SubjectLocationsExtractor.new(locations, @context).locations
  end
end
