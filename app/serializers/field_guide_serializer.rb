class FieldGuideSerializer
  include RestPack::Serializer
  include MediaLinksSerializer

  attributes :id, :items, :language, :href, :created_at, :updated_at

  can_include :project
  media_include :attached_images
end
