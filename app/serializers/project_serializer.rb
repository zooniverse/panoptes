class ProjectSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer

  attributes :id, :display_name, :classifications_count,
             :subjects_count, :created_at, :updated_at, :available_languages,
             :title, :description, :guide, :team_members, :science_case,
             :introduction, :avatar, :background_image, :private, :faq, :result,
             :education_content, :retired_subjects_count, :configuration,
             :beta, :approved, :live

  can_include :workflows, :subject_sets, :owners, :project_contents,
              :project_roles
  can_filter_by :display_name, :beta, :approved

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

  def education_content
    content[:education_content]
  end

  def faq
    content[:faq]
  end

  def result
    content[:result]
  end

  def content
    @content ||= _content
  end

  def _content
    content = @model.content_for(@context[:languages])
    content = @context[:fields].map{ |k| Hash[k, content.send(k)] }.reduce(&:merge)
    content.default_proc = proc { |hash, key| "" }
    content
  end
end
