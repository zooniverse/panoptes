class ClassificationSerializer
  include Serialization::PanoptesRestpack
  include NoCountSerializer
  include FilterHasMany

  attributes :id, :annotations, :created_at, :updated_at, :metadata, :href

  can_include :project, :user, :user_group, :workflow

  preload :subjects

  def self.page(params = {}, scope = nil, context = {})
    # only distinct classifications for multiple subjects
    if params.key?(:subject_id)
      scope = scope.distinct
    end

    page = super(params, scope, context)

    add_last_id_paging_hrefs(params, page)
  end

  # last_id is an mechanism to avoid offset paging
  # ensure we update the next/prev hrefs in the meta paging info for clients to use.
  # Do not let them keep the same last_id param and just page into that scope with offsets
  def self.add_last_id_paging_hrefs(params, page)
    if params.key?(:last_id)
      sorted_ids = page[:classifications].map { |c| c[:id] }.sort
      next_last_id = sorted_ids.last
      href_key_ids = { next_href: next_last_id, previous_href: params[:last_id] }
      href_key_ids.map do |href_key, next_id|
        href = page[:meta][:classifications][href_key]
        next unless href
        page[:meta][:classifications][href_key] = updated_last_id_href(href, next_id)
      end
    end
    page
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

  def self.updated_last_id_href(href, next_id)
    parsed_uri = URI.parse(href)
    path = parsed_uri.path
    uri_params = Rack::Utils.parse_nested_query(parsed_uri.query)
    no_page_href = uri_params.except("page").merge("last_id" => next_id)
    "#{path}?#{no_page_href.to_query}"
  end
end
