class SubjectSerializer
  include RestPack::Serializer
  include FilterHasMany

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at, :retired, :already_seen
  can_include :project, :collections

  def locations
    @model.locations.map do |loc|
      {
       loc.content_type => @context[:post_urls] ? loc.put_url : loc.get_url
      }
    end
  end

  def retired
    @context[:retired]
  end

  def already_seen
    @context[:already_seen]
  end
end
