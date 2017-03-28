class ClassificationSerializer
  include Serialization::PanoptesRestpack
  include NoCountSerializer
  include FilterHasMany
  include CachedSerializer

  attributes :id, :annotations, :created_at, :metadata, :href

  can_include :project, :user, :user_group, :workflow

  preload :subjects

  def self.page(params = {}, scope = nil, context = {})
    # only distinct classifications for multiple subjects
    if params.key?(:subject_id)
      scope = scope.distinct
    end

    super(params, scope, context)
  end

  def metadata
    @model.metadata.merge(workflow_version: @model.workflow_version)
  end

  def add_links(model, data)
    data = super(model, data)
    data[:links][:subjects] = model.subject_ids.map(&:to_s)
    data
  end

  def self.links
    links = super
    links["#{key}.subjects"] = {
      type: "subjects",
      href: "/subjects/{#{key}.subjects}"
    }
    links
  end
end
