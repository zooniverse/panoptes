class FieldGuideSerializer
  include Serialization::PanoptesRestpack
  include MediaLinksSerializer
  include CachedSerializer

  attributes :id, :items, :language, :href, :created_at, :updated_at

  can_include :project
  media_include :attached_images
  can_filter_by :language
end
