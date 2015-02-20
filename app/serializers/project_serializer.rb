class ProjectSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer

  attributes :id, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :title, :description, :guide, :team_members, :science_case,
    :introduction, :avatar, :background_image, :private

  can_include :workflows, :subject_sets, :owners, :project_contents,
    :project_roles
  can_filter_by :display_name

  def title
    content[:title]
  end

  def description
    content[:description]
  end

  def guide
    content[:guide]
  end

  def team_members
    content[:team_members]
  end

  def science_case
    content[:science_case]
  end

  def introduction
    content[:introduction]
  end

  def content
    @content ||=
      if content = @model.content_for(@context[:languages] || [@model.primary_language],
                                      @context[:fields])
        content = @context[:fields].map do
          |k| Hash[k, content.send(k)]
        end.reduce(&:merge)
        content.default_proc = proc { |hash, key| "" }
        content
      else
        Hash.new { |hash, key| "" }
      end
  end
end
