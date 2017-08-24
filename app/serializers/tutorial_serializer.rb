class TutorialSerializer
  include Serialization::PanoptesRestpack
  include MediaLinksSerializer
  include CachedSerializer

  attributes :steps, :href, :id, :created_at, :updated_at, :language, :kind, :display_name

  can_include :project
  can_include :workflows
  media_include :attached_images
  can_filter_by :language
end
