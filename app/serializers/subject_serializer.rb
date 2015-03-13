class SubjectSerializer

  include RestPack::Serializer
  attributes :id, :metadata, :locations, :zooniverse_id, :created_at, :updated_at,
             :retired, :already_seen
  can_include :project

  def locations
    SubjectLocationsExtractor.new(@model, @context).locations
  end

  def retired
    @context[:retired]
  end

  def already_seen
    @context[:already_seen]
  end
end
