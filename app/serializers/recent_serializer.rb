class RecentSerializer
  include RestPack::Serializer

  attributes :id, :created_at, :locations
  can_include :project, :workflow, :subject

  def locations
    @model.locations.map{ |loc| {loc.content_type => loc.get_url} }
  end
end

