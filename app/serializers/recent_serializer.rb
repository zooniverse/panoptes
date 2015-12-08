class RecentSerializer
  include RestPack::Serializer

  attributes :id, :created_at, :locations, :href
  can_include :project, :workflow, :subject
  can_sort_by :created_at

  def href
    "/#{@context[:type].pluralize}/#{@context[:owner_id]}/recents/#{@model.id}"
  end

  def locations
    @model.locations.map{ |loc| {loc.content_type => loc.get_url} }
  end
end
