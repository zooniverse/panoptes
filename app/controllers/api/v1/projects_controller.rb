class Api::V1::ProjectsController < Api::ApiController
  doorkeeper_for :update, :create, :delete, scopes: [:project]

  after_action :verify_authorized, except: :index

  def show
    project = Project.find(params[:id])
    authorize project, :read?
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
    content = ProjectContent.new(
      description: params.delete(:description),
      title: params[:display_name],
      language: params[:primary_language]
    )

    params[:project_contents] = [content]
    params[:owner] = current_resource_owner

    project = Project.new(params)
    authorize project, :create?
    project.save!

    render json_api: ProjectSerializer.resource(project,
                                                nil,
                                                languages: [params[:primary_language]],
                                                fields: ['title',
                                                         'description'])
  end

  def destroy
    project = Project.find(params[:id])
    authorize project, :destroy?
    project.destroy
    deleted_resource_response
  end

  private

    def add_owner_ids_filter_param!
      owner_filter = params.delete(:owner)
      owner_ids = OwnerName.where(name: owner_filter).map(&:resource_id).join(",")
      params.merge!({ owner_ids: owner_ids }) unless owner_ids.blank?
    end
end
