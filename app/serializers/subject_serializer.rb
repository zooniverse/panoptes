class SubjectSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany
  include MediaLinksSerializer


  attributes :id, :metadata, :locations, :zooniverse_id, :external_id,
    :created_at, :updated_at, :href

  can_include :project, :collections, :subject_sets
  media_include :attached_images

  preload :locations, :project, :collections, :subject_sets, :attached_images

  can_sort_by :id

  def locations
    @model.ordered_locations.map do |loc|
      {
       loc.content_type => loc.url_for_format(@context[:url_format] || :get)
      }
    end
  end
end
