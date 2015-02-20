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

  def create_response(projects)
    serializer.resource({ include: 'owners' },
                        resource_scope(projects),
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

  def new_items(resource, relation, value)
    super(resource, relation, value).map do |object|
      object.dup.tap do |dup_object|
        if dup_object.is_a?(Workflow)
          dup_object.workflow_contents = object.workflow_contents.map(&:dup)
        end
      end
    end
  end

  def context
    case action_name
    when "index"
      { languages: current_languages, fields: INDEX_FIELDS }
    when "show"
      { languages: current_languages, fields: CONTENT_FIELDS }
    else
      { fields: CONTENT_FIELDS }
    end
  end
end
