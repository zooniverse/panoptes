class Api::V1::ProjectsController < Api::ApiController
  include FilterByOwner

  doorkeeper_for :update, :create, :destroy, scopes: [:project]
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

  before_action :add_owner_ids_to_filter_param!, only: :index

  private
  
  def create_response(project)
    serializer.resource({ id: project.id, include: 'owners'},
                        nil,
                        languages: [ project.primary_language ],
                        fields: CONTENT_FIELDS)
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
    create_params[:project_contents] = [ProjectContent.new(content_from_params(create_params))]
    add_user_as_linked_owner(create_params)
    super(create_params)
  end

  def build_update_hash(update_params, id)
    content_update = content_from_params(update_params)
    unless content_update.blank?
      Project.find(id).primary_content.update!(content_update)
    end
    super(update_params, id)
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
