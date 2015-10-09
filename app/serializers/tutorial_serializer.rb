class TutorialSerializer
  include RestPack::Serializer
  include MediaLinksSerializer

  attributes :steps, :href, :id, :created_at, :updated_at, :language

  can_include :project
  media_include :attached_images
end
