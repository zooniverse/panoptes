class ProjectSerializer
  include Serialization::PanoptesRestpack
  include OwnerLinkSerializer
  include MediaLinksSerializer
  include CachedSerializer

  attributes :id, :display_name, :classifications_count,
    :subjects_count, :created_at, :updated_at, :available_languages,
    :title, :description, :introduction, :private, :retired_subjects_count,
    :configuration, :live, :urls, :migrated, :classifiers_count, :slug, :redirect,
    :beta_requested, :beta_approved, :launch_requested, :launch_approved, :launch_date,
    :href, :workflow_description, :primary_language, :tags, :experimental_tools,
    :completeness, :activity, :state, :researcher_quote, :mobile_friendly, :featured

  optional :avatar_src
  can_include :workflows, :active_workflows, :subject_sets, :owners,
    :project_roles, :pages, :organization
  media_include :avatar, :background, :attached_images,
    classifications_export: { include: false},
    subjects_export: { include: false }
  can_filter_by :display_name, :slug, :beta_requested, :beta_approved,
    :launch_requested, :launch_approved, :private, :state, :live,
    :mobile_friendly, :organization_id, :featured
  can_sort_by :launch_date, :activity, :completeness, :classifiers_count,
    :updated_at, :display_name

  # note: workflow(s) associations are preloaded via the
  # self.serialize_page(page, options) below
  preload :subject_sets,
          :project_roles,
          [owner: { identity_membership: :user }],
          :pages,
          :attached_images,
          :avatar,
          :background,
          :tags,
          :classifications_export,
          :subjects_export

  def self.page(params = {}, scope = nil, context = {})
    if Project.states.include?(params["state"])
      params["state"] = Project.states[params["state"]]
    elsif params["state"] == "live"
      params["live"] = true
      # ensure we only look for projects missing the paused, finished enum states
      # this indicates we missed the true state of a project in the enum
      # we should have an active state instead of checking if state is null
      params.delete("state")
      scope = scope.where(state: nil)
    end

    super(params, scope, context)
  end

  def self.paging_scope(params, scope, context)
    if context[:cards]
      scope.preload(:avatar)
    else
      super(params, scope, context)
    end
  end

  # override the serialize page method to preload the workflows
  # and active_workflows association data while avoid loading
  # large json attributes instead load only the data required
  # for serializing project & links
  def self.serialize_page(page, options)
    project_ids = page.pluck(:id)
    preloadable_workflows = preload_workflows(project_ids)
    page.map do |project_model|
      # select the model relations for assigning to the workflow associations
      project_model_workflows = preloadable_workflows.select do |workflow|
        workflow.project_id == project_model.id
      end
      project_model_active_workflows = preloadable_workflows.select do |workflow|
        workflow.active && workflow.project_id == project_model.id
      end
      # assign the preloaded workflow records to the model associations targets
      # use .target here to avoid loading the association before assignment
      # and thus undoing all the hard work to load only what we need
      project_model.association(:workflows).target = project_model_workflows
      project_model.association(:active_workflows).target = project_model_active_workflows

      self.as_json(project_model, options.context)
    end
  end

  def self.preload_workflows(project_ids)
    non_json_attrs = Workflow.attribute_names - Workflow::JSON_ATTRIBUTES
    # convert these to a workflow scope for reuse if viable
    # preload the workflow resources without json data attributes
    # get all worklfows as the active_workflows relation is a subset of the workflows
    Workflow
      .active
      .where(project_id: project_ids, serialize_with_project: true)
      .select(*non_json_attrs)
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
end
