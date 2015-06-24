class ProjectContentSerializer
  include RestPack::Serializer
  attributes :id, :language, :title, :description, :guide, :team_members,
    :science_case, :introduction, :faq, :result, :education_content, :href,
    :workflow_description

  can_include :project
end
