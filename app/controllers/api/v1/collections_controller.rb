class Api::V1::CollectionsController < Api::ApiController
  include FilterByOwner
  include FilterByCurrentUserRoles
  include IndexSearch

  before_action :filter_by_project_ids, only: :index
  before_action :pluralize_project_links, only: :create

  require_authentication :create, :update, :destroy, scopes: [:collection]
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

  def add_relation(resource, relation, value)
    if relation == :subjects && value.is_a?(Array)
      resource.project_ids = update_project_ids(resource, value)
    end
    super
  end

  def destroy_relation(resource, relation, value)
    if relation == :subjects
      unlink_ids = value.split(",")
      linked_project_ids = resource.subjects.where.not(id: unlink_ids).uniq.pluck(:project_id)
      resource.project_ids = linked_project_ids
    end
    super
  end

  private

  def params_project_ids
    @params_project_ids ||= (params.delete(:project_ids) || params.delete(:project_id)).try(:split, ',')
  end

  def filter_by_project_ids
    if project_ids = params_project_ids
      @controlled_resources = controlled_resources.where.overlap(project_ids: project_ids)
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

  def update_project_ids(resource, value)
    append_project_ids = if params_project_ids.blank?
      Subject.unscoped.uniq.where(id: value).pluck(:project_id)
    else
      params_project_ids
    end
    resource.project_ids | append_project_ids
  end
end
