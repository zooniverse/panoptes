class Api::V1::ProjectsController < Api::ApiController
  include FilterByOwner
  include FilterByCurrentUserRoles
  include TranslatableResource
  include IndexSearch
  include AdminAllowed
  include Versioned

  require_authentication :update, :create, :destroy, :create_classifications_export,
    :create_subjects_export, :create_aggregations_export,
    :create_workflows_export, :create_workflow_contents_export,
    scopes: [:project]
  resource_actions :show, :index, :create, :update, :deactivate
  schema_type :json_schema

  alias_method :project, :controlled_resource

  CONTENT_PARAMS = [:description,
                    :title,
                    :workflow_description,
                    :introduction]

  CONTENT_FIELDS = [:title,
                    :description,
                    :workflow_description,
                    :introduction,
                    :url_labels]

  before_action :eager_load_relations, only: :index
  before_action :filter_by_tags, only: :index
  before_action :downcase_slug, only: :index

  prepend_before_action :require_login,
    only: [:create, :update, :destroy, :create_classifications_export,
    :create_subjects_export, :create_aggregations_export,
    :create_workflows_export, :create_workflow_contents_export]

  search_by do |name, query|
    query.search_display_name(name.join(" "))
  end

  search_by :tag do |name, query|
    query.joins(:tags).merge(Tag.search_tags(name.first))
  end

  def fast_index
    render json_api: FastProjectSerializer.new(params).serialize
  end

  def index
    return fast_index if params[:simple]
    unless params.has_key?(:sort)
      @controlled_resources = case
                              when params.has_key?(:launch_approved)
                                controlled_resources.rank(:launched_row_order)
                              when params.has_key?(:beta_approved)
                                controlled_resources.rank(:beta_row_order)
                              else
                                controlled_resources
                              end
    end
    super
  end

  def create_classifications_export
    create_export(:classifications)
  end

  def create_subjects_export
    create_export(:subjects)
  end

  def create_aggregations_export
    create_export(:aggregations)
  end

  def create_workflows_export
    create_export(:workflows)
  end

  def create_workflow_contents_export
    create_export(:workflow_contents)
  end

  def create
    super { |project| TalkAdminCreateWorker.perform_async(project.id) }
  end

  private

  def downcase_slug
    if params.has_key? "slug"
      params[:slug] = params[:slug].downcase
    end
  end

  def filter_by_tags
    if tags = params.delete(:tags).try(:split, ",").try(:map, &:downcase)
      @controlled_resources = controlled_resources
      .joins(:tags).where(tags: {name: tags})
    end
  end

  def default_eager_loads
    !!params[:cards] ? [:avatar] : [:tags, :background, :avatar, :owner]
  end

  def allowed_eager_loads
    non_owner_role_params = [true, false].include?(@owner_eager_load)
    excepts = non_owner_role_params ? [:owner] : []
    (default_eager_loads - excepts).uniq
  end

  def eager_load_relations
    eager_loads = allowed_eager_loads
    unless eager_loads.empty?
      @controlled_resources = controlled_resources.eager_load(*eager_loads)
    end
  end

  def create_or_update_medium(type, media_create_params=media_params)
    media_create_params['metadata'] ||= { recipients: [api_user.id] }
    if medium = controlled_resource.send(type)
      medium.update!(media_create_params)
      medium.touch
      medium
    else
      media_create_params['metadata']["state"] = 'creating'
      controlled_resource.send("create_#{type}!", media_create_params)
    end
  end

  def media_params
    @media_params ||= params.require(:media).permit(:content_type, metadata: [recipients: []])
  end

  def medium_response(medium)
    headers['Location'] = "#{request.protocol}#{request.host_with_port}/api#{medium.location}"
    headers['Last-Modified'] = medium.updated_at.httpdate
    json_api_render(:created, MediumSerializer.resource({}, Medium.where(id: medium.id)))
  end

  def create_response(projects)
    serializer.resource({ include: 'owners' },
      resource_scope(projects),
      fields: CONTENT_FIELDS)
  end

  def content_from_params(ps)
    ps[:title] = ps[:display_name]
    content = ps.slice(*CONTENT_FIELDS)
    content[:language] = ps[:primary_language]
    if ps.has_key? :urls
      urls, labels = extract_url_labels(ps[:urls])
      content[:url_labels] = labels
      ps[:urls] = urls
    end
    ps.except!(*CONTENT_FIELDS)
    content.select { |k,v| !!v }
  end

  def admin_allowed_params
    [ :beta_approved, :launch_approved, :redirect,
      :launched_row_order_position, :beta_row_order_position,
      :experimental_tools ]
  end

  def build_resource_for_create(create_params)
    admin_allowed create_params, *admin_allowed_params
    create_params[:project_contents] = [ProjectContent.new(content_from_params(create_params))]
    if create_params.has_key? :tags
      create_params[:tags] = create_or_update_tags(create_params)
    end
    add_user_as_linked_owner(create_params)
    super(create_params)
  end

  def build_update_hash(update_params, id)
    admin_allowed update_params, *admin_allowed_params
    content_update = content_from_params(update_params)
    unless content_update.blank?
      Project.find(id).primary_content.update!(content_update)
    end
    tags = create_or_update_tags(update_params)
    unless tags.nil?
      p = Project.find(id)
      p.tags = tags
      p.save!
    end
    if update_params[:live] == false
      update_params[:launch_approved] = false
      update_params[:beta_approved] = false
    end
    super(update_params, id)
  end

  def new_items(resource, relation, value)
    construct_new_items(super(resource, relation, value), resource.id)
  end

  def construct_new_items(item_scope, project_id)
    Array.wrap(item_scope).map do |item|
      case item
      when Workflow
        item.dup.tap do |dup_object|
          dup_object.workflow_contents = item.workflow_contents.map(&:dup)
        end
      when SubjectSet
        if !item.belongs_to_project?(project_id)
          SubjectSetCopier.new(item, project_id).duplicate_subject_set_and_subjects
        else
          item
        end
      end
    end
  end

  def create_or_update_tags(hash)
    hash.delete(:tags).try(:map) do |tag|
      name = tag.downcase
      Tag.find_or_initialize_by(name: name)
    end
  end

  def extract_url_labels(urls)
    visitor = TasksVisitors::ExtractStrings.new
    visitor.visit(urls)
    [urls, visitor.collector]
  end

  def create_export(export_type)
    medium = create_or_update_medium("#{export_type}_export".to_sym)
    dump_worker_klass = "#{export_type.to_s.camelize}DumpWorker".constantize
    dump_worker_klass.perform_async(controlled_resource.id, medium.id, api_user.id)
    medium_response(medium)
  end

  def context
    if action_name == "index" && !!params[:cards]
      exclude_keys = ProjectSerializer.serializable_attributes
        .except(:id, :display_name, :description, :slug, :redirect, :avatar_src).keys
      {cards: true, include_avatar_src?: true}.tap do |context|
        exclude_keys.map do |k|
          context["include_#{k}?".to_sym] = false
        end
      end
    else
      super
    end
  end
end
