class Api::V1::ProjectsController < Api::ApiController
  include Destructable
  
  doorkeeper_for :update, :create, :delete, scopes: [:project]
  access_control_for :create, :update, :destroy, resource_class: Project

  alias_method :project, :controlled_resource
  
  def show
    render json_api: ProjectSerializer.resource(params,
                                                visible_scope(api_user),
                                                languages: current_languages,
                                                fields: ['title',
                                                         'description',
                                                         'example_strings',
                                                         'pages'])
  end

  def index
    add_owner_ids_filter_param!
    render json_api: ProjectSerializer.page(params,
                                            visible_scope(api_user),
                                            languages: current_languages,
                                            fields: ['title', 'description'])
  end

  def update
    # TODO: implement JSON-Patch or find a gem that does
  end

  def create
    owner = owner_from_params || api_user.user
    project = create_project(owner)

    json_api_render(201,
                    create_project_response(project),
                    api_project_url(project) )
  end

  private

  def resource_serializer(*args)
    ProjectSerializer.resource(*args)
  end

  def add_owner_ids_filter_param!
    owner_filter = params.delete(:owner)
    owner_ids = OwnerName.where(name: owner_filter).map(&:resource_id).join(",")
    params.merge!({ owner_ids: owner_ids }) unless owner_ids.blank?
  end

  def create_project_response(project)
    resource_serializer(project,
                        nil,
                        languages: [ params[:project][:primary_language] ],
                        fields: ['title', 'description'] )
  end

  def creation_params
    params.require(:project)
      .permit(:description, :display_name, :name, :primary_language)
  end

  def project_params
    project_params = creation_params.dup
    project_params.delete(:description)
    project_params
  end

  def content_params
    content_params = creation_params.dup
    content_params.delete(:name)
    content_params[:title] = content_params.delete(:display_name)
    content_params[:language] = content_params.delete(:primary_language)
    content_params
  end

  def create_project(owner)
    project = Project.new(project_params)
    content = Project.content_model.new(content_params)
    project.owner = owner

    ActiveRecord::Base.transaction do
      project.save!
      content.project = project
      content.save!
    end

    project
  end
end 
