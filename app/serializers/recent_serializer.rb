class RecentSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :created_at, :updated_at, :locations, :href
  can_include :project, :workflow, :subject
  can_sort_by :created_at

  preload :locations

  def href
    "/#{@context[:url_prefix]}/recents/#{@model.id}"
  end

  def locations
    @model.ordered_locations.map do |loc|
      { loc.content_type => loc.get_url }
    end
  end
end
