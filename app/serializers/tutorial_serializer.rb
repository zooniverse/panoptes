class TutorialSerializer
  include RestPack::Serializer
  include MediaLinksSerializer

  attributes :steps, :href, :id, :created_at, :updated_at, :language, :kind

  can_include :project
  can_include :workflows
  media_include :attached_images
end
