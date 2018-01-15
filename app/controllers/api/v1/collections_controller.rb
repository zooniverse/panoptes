class Api::V1::CollectionsController < Api::ApiController
  include FilterByOwner
  include FilterByCurrentUserRoles
  include IndexSearch

  before_action :filter_by_project_ids, only: :index
  before_action :pluralize_project_links, only: :create
  before_action :link_up_habtm_projects, only: :create # TODO: After PR 2563, remove this

  require_authentication :create, :update, :destroy, scopes: [:collection]
  resource_actions :default
  schema_type :strong_params

  # TODO: After 2563, remove habtm_projects
  allowed_params :create, :name, :display_name, :private, :favorite, :description,
    links: [ :default_subject, :project, projects: [], habtm_projects: [], subjects: [], owner: polymorphic ]

  allowed_params :update, :name, :display_name, :private, :description, links: [ :default_subject, subjects: [] ]

  search_by do |name, query|
    query.search_display_name(name.join(" "))
  end

  def destroy_links
    super { |collection| check_default_subject(collection) }
  end

  protected

  def build_resource_for_create(create_params)
    add_user_as_linked_owner(create_params)
    super(create_params)
  end

  private

  def check_default_subject(collection)
    collection.update({ default_subject: nil }) if params["link_ids"].split(",").include? collection.default_subject&.id.to_s
  end

  def filter_by_project_ids
    if ids_string = (params.delete(:project_ids) || params.delete(:project_id)).try(:split, ',')
      project_ids = ids_string.split(",")
      @controlled_resources = controlled_resources.where.overlap(project_ids: project_ids)
      # TODO: PR 2563 followup: @controlled_resources = controlled_resources.joins(:projects).where(projects: {id: project_ids})
    end
  end

  def pluralize_project_links
    collection_params = params[:collections]
    if project_id = collection_params[:links].try(:delete, :project)
      if collection_params[:links][:projects]
        raise BadLinkParams.new("Error: project_ids and project link keys must not be set together")
      end
      collection_params[:links].merge!(projects: [project_id])
    end
  end

  # TODO: After PR 2563 remove this
  def link_up_habtm_projects
    collection_params = params[:collections]
    return unless collection_params[:links]

    if project_ids = collection_params[:links][:projects]
      collection_params[:links].merge!(habtm_projects: project_ids)
    end
  end
end
