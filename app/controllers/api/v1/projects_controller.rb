class Api::V1::ProjectsController < Api::ApiController
  doorkeeper_for :update, :create, :delete, scopes: [:project]

  after_action :verify_authorized, except: :index

  def show
    project = Project.find(params[:id])
    authorize project, :read?
    render json_api: ProjectSerializer.resource(project, nil,
                                                {languages: current_languages,
                                                fields: ['title',
                                                         'description',
                                                         'example_strings',
                                                         'pages']})
  end

  def index
    render json_api: ProjectSerializer.page(params, nil,
                                            {languages: current_languages,
                                            fields: ['title', 'description']})
  end

  def update
    # TODO: implement JSON-Patch or find a gem that does
  end

  def create

  end

  def delete
  
  end
end 
