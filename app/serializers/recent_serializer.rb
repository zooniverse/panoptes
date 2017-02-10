class RecentSerializer
  include RestPack::Serializer

  attributes :id, :created_at, :locations, :href
  can_include :project, :workflow, :subject
  can_sort_by :created_at

  def self.page(params = {}, scope = nil, context = {})
    scope = scope.preload(subject: :locations)
    super(params, scope, context)
  end

  def href
    "/#{@context[:type].pluralize}/#{@context[:owner_id]}/recents/#{@model.id}"
  end

  def locations
    @model.subject.ordered_locations.map do |loc|
      { loc.content_type => loc.get_url }
    end
  end
end
