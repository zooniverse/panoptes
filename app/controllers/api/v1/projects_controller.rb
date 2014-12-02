class Api::V1::ProjectsController < Api::ApiController
  include JsonApiController
  
  doorkeeper_for :update, :create, :delete, scopes: [:project]
  resource_actions :default
  schema_type :json_schema

  alias_method :project, :controlled_resource

  CONTENT_PARAMS = [:description,
                    :science_case,
                    :introduction,
                    team_members: [:name, :bio, :twitter, :institution],
                    guide: [:image, :explanation]] 

  CONTENT_FIELDS = [:title,
                    :description,
                    :guide,
                    :team_members,
                    :science_case,
                    :introduction]

  INDEX_FIELDS = [:title, :description]
  
  allowed_params :create
  allowed_params :update

  before_action :add_owner_ids_to_filter_param!, only: :index
  
  private

  def add_owner_ids_to_filter_param!
    if owner_filter = params.delete(:owner)
      owner_ids = OwnerName.where(name: owner_filter).map(&:resource_id).join(",")
      params.merge!({ owner_ids: owner_ids }) unless owner_ids.blank?
    end
  end

  def content_from_params(ps)
    ps[:title] = ps[:display_name]
    content = ps.slice(*CONTENT_FIELDS)
    content[:language] = ps[:primary_language]
    ps.except!(*CONTENT_FIELDS)
    content.select { |k,v| !!v } 
  end

  def build_resource_for_create(create_params)
    Namer.set_name_fields(create_params)
    
    content_params = content_from_params(create_params)
    
    create_params[:links] ||= Hash.new
    create_params[:links][:owner] = owner || api_user.user

    project = super(create_params)
    project.project_contents.build(**content_params.symbolize_keys)
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

  def context
    { languages: language_context, fields: field_content }
  end

  def language_context
    case action_name
    when "show", "index"
      current_languages
    when "update", "create"
      [ project.primary_language ]
    end
  end

  def field_content
    case action_name
    when "index"
      INDEX_FIELDS
    when "show", "update", "create"
      CONTENT_FIELDS
    end
  end
end 
