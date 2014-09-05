class Api::V1::ProjectsController < Api::ApiController
  doorkeeper_for :update, :create, :delete, scopes: [:project]
  access_control_for :create, :update, :destroy, resource_class: Project

  alias_method :project, :controlled_resource
  
  def show
    render json_api: serializer.resource(params,
                                         visible_scope,
                                         languages: current_languages,
                                         fields: ['title',
                                                  'description',
                                                  'example_strings',
                                                  'pages'])
  end

  def index
    add_owner_ids_filter_param!
    render json_api: serializer.page(params,
                                     visible_scope,
                                     languages: current_languages,
                                     fields: ['title', 'description'])
  end

  def update
    # TODO: implement JSON-Patch or find a gem that does
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
                        languages: [ params[:project][:primary_language] ],
                        fields: ['title', 'description'] )
  end

  def create_params
    params.require(:project)
      .permit(:description, :display_name, :name, :primary_language)
  end

  def create_project_params
    project_params = create_params.dup
    project_params.delete(:description)
    project_params
  end

  def create_content_params
    content_params = create_params.dup
    content_params.delete(:name)
    content_params[:title] = content_params.delete(:display_name)
    content_params[:language] = content_params.delete(:primary_language)
    content_params
  end

  def create_resource
    project = Project.new(create_project_params)
    content = Project.content_model.new(create_content_params)
    project.owner = owner

    ActiveRecord::Base.transaction do
      project.save!
      content.project = project
      content.save!
    end

    project if project.persisted? && content.persisted?
  end
end 
