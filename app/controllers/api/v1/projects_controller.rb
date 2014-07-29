class Api::V1::ProjectsController < Api::ApiController
  doorkeeper_for :update, :create, :delete, scopes: [:project]

  def show
    project = Project.find(params[:id])
    render json_api: ProjectSerializer.resource(project,
                                                nil,
                                                languages: current_languages,
                                                fields: ['title',
                                                         'description',
                                                         'example_strings',
                                                         'pages'])
  end

  def index
    add_owner_ids_filter_param!
    render json_api: ProjectSerializer.page(params,
                                            nil,
                                            languages: current_languages,
                                            fields: ['title', 'description'])
  end

  def update
    # TODO: implement JSON-Patch or find a gem that does
  end

  def create
    project_attributes = project_params

    content = Project.content_model.new(
      description: project_attributes.delete(:description),
      title: project_attributes[:display_name],
      language: project_attributes[:primary_language]
    )

    project = Project.new(project_attributes)
    project.owner = current_resource_owner

    ActiveRecord::Base.transaction do
      project.save!
      content.project = project
      content.save!
    end

    json_api_render( 201,
                     create_project_response(project),
                     api_project_url(project) )
  end

  def destroy
    project = Project.find(params[:id])
    project.destroy
    deleted_resource_response
  end

  private

  def add_owner_ids_filter_param!
    owner_filter = params.delete(:owner)
    owner_ids = OwnerName.where(name: owner_filter).map(&:resource_id).join(",")
    params.merge!({ owner_ids: owner_ids }) unless owner_ids.blank?
  end

  def create_project_response(project)
    ProjectSerializer.resource( project,
                                nil,
                                languages: [ params[:project][:primary_language] ],
                                fields: ['title', 'description'] )
  end

  def project_params
    params.require(:project).permit(:display_name, :name, :description, :primary_language)
  end
end 
