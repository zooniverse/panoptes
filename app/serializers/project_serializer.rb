require "tasks_visitors/inject_strings"

class ProjectSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include MediaLinksSerializer

  attributes :id, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :title, :description, :introduction, :private, :retired_subjects_count,
    :configuration, :live, :urls, :migrated, :classifiers_count, :slug, :redirect,
    :beta_requested, :beta_approved, :launch_requested, :launch_approved, :launch_date,
    :href, :workflow_description, :primary_language, :tags, :experimental_tools,
    :completeness, :activity

  optional :avatar_src
  can_include :workflows, :subject_sets, :owners, :project_contents,
    :project_roles, :pages
  media_include :avatar, :background, :attached_images,
    classifications_export: { include: false},
    subjects_export: { include: false },
    aggregations_export: { include: false }
  can_filter_by :display_name, :slug, :beta_requested, :beta_approved,
    :launch_requested, :launch_approved, :private
  can_sort_by :launch_date, :activity, :completeness, :classifiers_count,
    :updated_at, :display_name

  def self.links
    links = super
    links["projects.pages"] = {
                               href: "/projects/{projects.id}/pages",
                               type: "project_pages"
                              }
    links
  end

  def add_links(model, data)
    if @context[:cards]
      data.merge!(links: {})
    else
      super(model, data)
    end
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

  def avatar_src
    if avatar = @model.avatar
      avatar.external_link ? avatar.external_link : avatar.src
    else
      ""
    end
  end

  def fields
    %i(title description workflow_description introduction url_labels)
  end

  def _content
    content = @model.content_for(@context[:languages])
    content = fields.map{ |k| Hash[k, content.send(k)] }.reduce(&:merge)
    content.default_proc = proc { |hash, key| "" }
    content
  end
end
