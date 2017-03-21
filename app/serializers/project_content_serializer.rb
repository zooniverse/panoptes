class ProjectContentSerializer
  include RestPack::Serializer
  include CachedSerializer

  attributes :id, :language, :title, :description, :introduction,
    :href, :workflow_description, :researcher_quote

  can_include :project
end
