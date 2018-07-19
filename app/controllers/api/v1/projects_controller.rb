class Api::V1::ProjectsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include FilterByOwner
  include FilterByCurrentUserRoles
  include SyncResourceTranslationStrings
  include IndexSearch
  include FilterByTags
  include AdminAllowed
  include Versioned
  include UrlLabels
  include ContentFromParams
  include Slug
  include MediumResponse

  require_authentication :update, :create, :destroy, :create_classifications_export,
    :create_subjects_export, :create_workflows_export, :create_workflow_contents_export,
    scopes: [:project]
  resource_actions :show, :index, :create, :update, :deactivate
  schema_type :json_schema

  alias_method :project, :controlled_resource

  CONTENT_FIELDS = [:title,
                    :description,
                    :workflow_description,
                    :introduction,
                    :researcher_quote,
                    :url_labels].freeze

  CARD_FIELDS = [:id,
                 :display_name,
                 :description,
                 :slug,
                 :redirect,
                 :avatar_src,
                 :classifications_count,
                 :updated_at,
                 :launch_approved].freeze

  prepend_before_action :require_login,
    only: [:create, :update, :destroy, :create_classifications_export,
    :create_subjects_export, :create_workflows_export, :create_workflow_contents_export]

  before_action :available_to_export, only: :create_classifications_export

  def index
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

  def update
    super do |resource|
      # TODO: extract this primary project content update
      # to a service object that sits in the project
      # transaction.
      content_attributes = primary_content_attributes(update_params)
      unless content_attributes.blank?
        resource.primary_content.update!(content_attributes)
      end

      tags = Tags::BuildTags.run!(api_user: api_user, tag_array: update_params[:tags]) if update_params[:tags]
      resource.tags = tags unless tags.nil?

      if !content_attributes.blank? || !tags.nil?
        resource.updated_at = Time.zone.now
      end
    end
  end

  def create_classifications_export
    medium = CreateClassificationsExport.with( api_user: api_user, object: controlled_resource ).run!(params)
    medium_response(medium)
  end

  def create_subjects_export
    medium = Projects::CreateSubjectsExport.with(api_user: api_user, object: controlled_resource).run!(params)
    medium_response(medium)
  end

  def create_workflows_export
    medium = Projects::CreateWorkflowsExport.with(api_user: api_user, object: controlled_resource).run!(params)
    medium_response(medium)
  end

  def create_workflow_contents_export
    medium = Projects::CreateWorkflowContentsExport.with(api_user: api_user, object: controlled_resource).run!(params)
    medium_response(medium)
  end

  def create
    super { |project| TalkAdminCreateWorker.perform_async(project.id) }
  end

  private

  def create_response(projects)
    serializer.resource(
      { include: 'owners' },
      resource_scope(projects),
      fields: CONTENT_FIELDS
    )
  end

  def admin_allowed_params
    [ :beta_approved, :launch_approved, :redirect,
      :launched_row_order_position, :beta_row_order_position,
      :experimental_tools, :featured ]
  end

  def build_resource_for_create(create_params)
    admin_allowed create_params, *admin_allowed_params

    content_attributes = primary_content_attributes(create_params)
    create_params[:project_contents] = [ ProjectContent.new(content_attributes) ]

    if create_params.key?(:tags)
      create_params[:tags] = Tags::BuildTags.run!(api_user: api_user, tag_array: create_params[:tags])
    end

    add_user_as_linked_owner(create_params)

    super(create_params.except(*CONTENT_FIELDS))
  end

  def build_update_hash(update_params, resource)
    admin_allowed update_params, *admin_allowed_params

    if update_params[:launch_approved]
      resource.launch_date ||= Time.zone.now
    end

    update_attributes = super(update_params, resource)
    update_attributes.except(:tags, *CONTENT_FIELDS)
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

  def context
    if action_name == "index" && !!params[:cards]
      {cards: true, include_avatar_src?: true}.tap do |context|
        cards_exclude_keys.map do |k|
          context["include_#{k}?".to_sym] = false
        end
      end
    else
      super
    end
  end

  def cards_exclude_keys
    ProjectSerializer.serializable_attributes.except(*CARD_FIELDS).keys
  end

  def primary_content_attributes(content_attributes)
    content_from_params(content_attributes.dup, CONTENT_FIELDS) do |ps|
      ps[:title] = ps[:display_name]
    end
  end

  def available_to_export
    if controlled_resource.keep_data_in_panoptes_only?
      raise Api::DisabledDataExport.new(
        "Data exports are disabled for this project"
      )
    end
  end
end
