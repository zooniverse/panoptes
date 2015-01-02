class ProjectSerializer
  include RestPack::Serializer
  attributes :id, :name, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :title, :description, :guide, :team_members, :science_case,
    :introduction, :avatar, :background_image

  can_include :workflows, :subject_sets, :owners, :project_contents,
    :project_roles
  can_filter_by :display_name, :name

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

  def add_links(model, data)
    data = super

    data[:links][:owner] = {id: @model.owner.id.to_s,
                            type: @model.owner.class.model_name.plural,
                            href: "#{@model.owner.class.model_name.route_key}/#{@model.owner.id}"}
    data
  end

  def self.links
    links = super
    links.delete("#{key}.owner")
    links
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
