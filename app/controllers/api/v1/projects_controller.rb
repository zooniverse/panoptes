class Api::V1::ProjectsController < Api::ApiController
  include JsonApiController
  
  before_filter :require_login, only: [:create, :update, :destroy]
  doorkeeper_for :update, :create, :delete, scopes: [:project]
  access_control_for :create, :update, :destroy, resource_class: Project

  alias_method :project, :controlled_resource

  resource_actions :update, :create, :destroy

  request_template :create, :description, :display_name, :name,
    :primary_language, links: [owner: polymorphic,
                               workflows: [],
                               subject_sets: []]
  
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

  private

  def add_owner_ids_filter_param!
    owner_filter = params.delete(:owner)
    owner_ids = OwnerName.where(name: owner_filter).map(&:resource_id).join(",")
    params.merge!({ owner_ids: owner_ids }) unless owner_ids.blank?
  end

  def create_response(project)
    serializer.resource(project,
                        nil,
                        languages: [ params[:projects][:primary_language] ],
                        fields: ['title', 'description'] )
  end


  def create_resource(create_params)
    title, language = create_params.values_at(:display_name,
                                              :primary_language)
    description = create_params.delete(:description)
    
    create_params[:links] ||= Hash.new
    create_params[:links][:owner] = owner || api_user.user

    project = super(create_params)
    project.project_contents.build(description: description,
                                   title: title,
                                   language: language)
    project
  end
end 
