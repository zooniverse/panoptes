class ProjectContentSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :language, :title, :description, :introduction,
    :href, :workflow_description, :researcher_quote

  can_include :project
end
