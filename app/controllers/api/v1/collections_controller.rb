class Api::V1::CollectionsController < Api::ApiController
  include FilterByOwner
  include FilterByCurrentUserRoles
  include IndexSearch

  before_action :filter_by_project_ids, only: :index
  before_action :pluralize_project_links, only: :create

  doorkeeper_for :create, :update, :destroy, scopes: [:collection]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :name, :display_name, :private, :favorite,
    links: [ :project, projects: [], subjects: [], owner: polymorphic ]

  allowed_params :update, :name, :display_name, :private, links: [ subjects: [] ]

  search_by do |name, query|
    query.search_display_name(name.join(" "))
  end

  protected

  def build_resource_for_create(create_params)
    add_user_as_linked_owner(create_params)
    super(create_params)
  end

  private

  def filter_by_project_ids
    if ids_string = (params.delete(:project_ids) || params.delete(:project_id)).try(:split, ',')
      project_ids = ids_string.split(",")
      @controlled_resources = controlled_resources.where.overlap(project_ids: project_ids)
    end
  end

  def pluralize_project_links
    if project_id = params[:collections][:links].try(:delete, :project)
      if create_params[:links][:projects]
        raise BadLinkParams.new("Error: project_ids and project link keys must not be set together")
      end
      create_params[:links].merge!(projects: [project_id])
    end
  end
end
