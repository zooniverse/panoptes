class SubjectSerializer
  include RestPack::Serializer
  include FilterHasMany

  attributes :id, :metadata, :locations, :zooniverse_id,
    :created_at, :updated_at, :retired, :already_seen
  can_include :project, :collections

  def locations
    @model.locations.reduce({}) do |hash, loc|
      {
       loc.content_type => @content[:post_urls] ? loc.put_url : loc.get_url
      }
    end.reduce(&:merge)
  end

  def retired
    @context[:retired]
  end

  def already_seen
    @context[:already_seen]
  end
end
