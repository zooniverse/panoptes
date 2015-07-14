class ProjectSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include MediaLinksSerializer

  attributes :id, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :title, :description, :introduction, :private, :retired_subjects_count,
    :configuration, :live, :urls, :migrated, :classifiers_count, :slug, :redirect,
    :beta_requested, :beta_approved, :launch_requested, :launch_approved,
    :href, :workflow_description, :primary_language, :tags

  can_include :workflows, :subject_sets, :owners, :project_contents,
    :project_roles, :pages
  can_filter_by :display_name, :slug, :beta_requested, :beta_approved, :launch_requested, :launch_approved
  media_include :avatar, :background, :attached_images, classifications_export: { include: false}

  def self.links
    links = super
    links["projects.pages"] = {
                               href: "/projects/{projects.id}/pages",
                               type: "project_pages"
                              }
    links
  end

  def title
    content[:title]
  end

  def description
    content[:description]
  end

  def workflow_description
    content[:workflow_description]
  end

  def introduction
    content[:introduction]
  end

  def urls
    if content
      urls = @model.urls.dup
      TasksVisitors::InjectStrings.new(content[:url_labels]).visit(urls)
      urls
    else
      []
    end
  end

  def content
    @content ||= _content
  end

  def tags
    @model.tags.map(&:name)
  end

  def _content
    content = @model.content_for(@context[:languages])
    content = @context[:fields].map{ |k| Hash[k, content.send(k)] }.reduce(&:merge)
    content.default_proc = proc { |hash, key| "" }
    content
  end
end
