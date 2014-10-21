class Api::V1::ProjectsController < Api::ApiController
  include JsonApiController
  
  doorkeeper_for :update, :create, :delete, scopes: [:project]
  resource_actions :update, :create, :destroy

  alias_method :project, :controlled_resource
  
  allowed_params :create, :description, :display_name, :name,
    :primary_language, links: [owner: polymorphic,
                               workflows: [],
                               subject_sets: []]

  allowed_params :update, :description, :display_name,
    links: [workflows: [], subject_sets: []]

  CONTENT_FIELDS = %W(title
                      description
                      guide
                      team_members
                      science_case
                      introduction)

  INDEX_FIELDS = %w(title description)

  def show
    render json_api: serializer.resource(params,
                                         visible_scope,
                                         languages: current_languages,
                                         fields: CONTENT_FIELDS)
  end

  def index
    add_owner_ids_filter_param!
    render json_api: serializer.page(params,
                                     visible_scope,
                                     languages: current_languages,
                                     fields: INDEX_FIELDS)
  end

  private

  def add_owner_ids_filter_param!
    owner_filter = params.delete(:owner)
    owner_ids = OwnerName.where(name: owner_filter).map(&:resource_id).join(",")
    params.merge!({ owner_ids: owner_ids }) unless owner_ids.blank?
  end

  def create_response(project)
    serializer.resource(project,
                        nil,
                        languages: [ project.primary_language ],
                        fields: ['title', 'description'] )
  end

  def update_response
    render json_api: create_response(project)
  end
  
  def content_from_params(ps)
    ps[:title] = ps[:display_name]
    content = ps.slice(*CONTENT_FIELDS)
    content[:language] = ps[:primary_language]
    ps.except!(*CONTENT_FIELDS)
    content.select { |k,v| !!v } 
  end

  def build_resource_for_create(create_params)
    content_params = content_from_params(create_params)
    
    create_params[:links] ||= Hash.new
    create_params[:links][:owner] = owner || api_user.user

    project = super(create_params)
    project.project_contents.build(**content_params)
    project
  end

  def build_resource_for_update(update_params)
    content_params = content_from_params(update_params)
    super(update_params)
    project.primary_content.update_attributes(content_params)
  end

  def new_items(relation, value)
    super(relation, value).map(&:dup)
  end
end 
