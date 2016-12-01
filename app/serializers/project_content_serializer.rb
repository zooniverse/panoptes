class ProjectContentSerializer
  include RestPack::Serializer
  attributes :id, :language, :title, :description, :introduction,
    :href, :workflow_description, :researcher_quote

  can_include :project
end
