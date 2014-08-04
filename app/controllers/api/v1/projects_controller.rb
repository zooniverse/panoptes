class Api::V1::ProjectsController < Api::ApiController
  doorkeeper_for :update, :create, :delete, scopes: [:project]

  def show
    project = Project.find(params[:id])
    api_user.do_to_resource(project, :read) do 
      render json_api: ProjectSerializer.resource(project,
                                                  nil,
                                                  languages: current_languages,
                                                  fields: ['title',
                                                           'description',
                                                           'example_strings',
                                                           'pages'])
    end
  end

  def index
    add_owner_ids_filter_param!
    render json_api: ProjectSerializer.page(params,
                                            Project.visible_to(api_user),
                                            languages: current_languages,
                                            fields: ['title', 'description'])
  end

  def update
    # TODO: implement JSON-Patch or find a gem that does
  end

  def create
    project = api_user.do_to_resource(Project, :create, as: owner_from_params) do |owner|
      create_project(owner)
    end

    json_api_render(201,
                    create_project_response(project),
                    api_project_url(project) )
  end

  def destroy
    api_user.do_to_resource(project, :destroy, as: owner_from_params) do |owner, project|
      project.destroy
    end
    deleted_resource_response
  end

  private

  def project
    Project.find(params[:id])
  end

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
    params.require(:project).permit(:display_name, :name, :primary_language)
  end

  def content_params
    params.require(:project).permit(:description, :display_name, :primary_language)
    .tap do |obj| 
      obj[:title] = obj.delete(:display_name)
      obj[:language] = obj.delete(:primary_language)
    end
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
