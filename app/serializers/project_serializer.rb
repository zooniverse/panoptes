class ProjectSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include MediaLinksSerializer
  include CachedSerializer

  CONTENT_FIELDS = %i(
    title description workflow_description
    introduction url_labels researcher_quote
  ).freeze

  PRELOADS = [
    :project_contents,
    :workflows,
    :active_workflows,
    :subject_sets,
    :project_roles,
    [ owner: { identity_membership: :user } ],
    :pages,
    :attached_images,
    :avatar,
    :background,
    :tags
  ].freeze

  attributes :id, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :title, :description, :introduction, :private, :retired_subjects_count,
    :configuration, :live, :urls, :migrated, :classifiers_count, :slug, :redirect,
    :beta_requested, :beta_approved, :launch_requested, :launch_approved, :launch_date,
    :href, :workflow_description, :primary_language, :tags, :experimental_tools,
    :completeness, :activity, :state, :researcher_quote, :mobile_friendly, :featured

  optional :avatar_src
  can_include :workflows, :active_workflows, :subject_sets, :owners, :project_contents,
    :project_roles, :pages, :organization
  media_include :avatar, :background, :attached_images,
    classifications_export: { include: false},
    subjects_export: { include: false }
  can_filter_by :display_name, :slug, :beta_requested, :beta_approved,
    :launch_requested, :launch_approved, :private, :state, :live,
    :mobile_friendly, :organization_id, :featured
  can_sort_by :launch_date, :activity, :completeness, :classifiers_count,
    :updated_at, :display_name

  def self.page(params = {}, scope = nil, context = {})
    if params.key?("state")
      if Project.states.include?(params["state"])
        params["state"] = Project.states[params["state"]]
      elsif params["state"] == "live"
        params["live"] = true
        params.delete("state")
        scope = scope.where(state: nil)
      end
    end

    preloads =
      if context[:cards]
        :avatar
      else
        PRELOADS
      end
    scope = scope.preload(*preloads)

    super(params, scope, context)
  end

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

  def urls
    urls = @model.urls.dup
    TasksVisitors::InjectStrings.new(@model.url_labels).visit(urls)
    urls
  end

  def tags
    if @model.tags.loaded?
      @model.tags.map(&:name)
    else
      @model.tags.pluck(:name)
    end
  end

  def avatar_src
    if avatar = @model.avatar
      avatar.external_link ? avatar.external_link : avatar.src
    else
      ""
    end
  end

  def content
    return @content if @content
    content = @model.primary_content.attributes.with_indifferent_access
    content.default = ""
    @content = content.slice(*CONTENT_FIELDS)
  end
end
