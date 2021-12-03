class Api::V1::ProjectsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include FilterByOwner
  include FilterByCurrentUserRoles
  include SyncResourceTranslationStrings
  include IndexSearch
  include FilterByTags
  include AdminAllowed
  include Slug
  include MediumResponse

  require_authentication :update, :create, :destroy, :create_classifications_export,
    :create_subjects_export, :create_workflows_export, :create_workflow_contents_export, :copy,
    scopes: [:project]
  resource_actions :show, :index, :create, :update, :deactivate
  schema_type :json_schema

  alias_method :project, :controlled_resource

  CARD_FIELDS = [:id,
                 :display_name,
                 :description,
                 :slug,
                 :redirect,
                 :avatar_src,
                 :classifications_count,
                 :updated_at,
                 :state,
                 :completeness,
                 :launch_approved].freeze

  prepend_before_action :require_login,
    only: [:create, :update, :destroy, :create_classifications_export,
    :create_subjects_export, :create_workflows_export, :create_workflow_contents_export]

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
      if update_params.key?(:urls)
        urls, labels = UrlLabels.extract_url_labels(update_params[:urls])
        resource.url_labels = labels
        resource.urls = urls
      end

      tags = Tags::BuildTags.run!(api_user: api_user, tag_array: update_params[:tags]) if update_params[:tags]

      unless tags.nil?
        resource.tags = tags
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
    head :gone
  end

  def create
    super { |project| TalkAdminCreateWorker.perform_async(project.id) }
  end

  def copy
    # check we are copying a template project
    template_project_to_copy = project.configuration.key?('template') && !project.live
    unless template_project_to_copy
      error_message = "The Project with id #{project.id} does not support copy functionality, check the configuration json has 'template' attribute and the project is not set as 'live'."
      raise(Api::MethodNotAllowed, error_message)
    end

    operations_params = params.slice(:create_subject_set).merge(project: project)
    copied_project = Projects::Copy.with(api_user: api_user).run!(operations_params)

    created_resource_response(copied_project)
  end

  private

  def create_response(project_scope)
    serializer.resource(
      { include: 'owners' },
      project_scope,
      context
    )
  end

  def admin_allowed_params
    %i[ beta_approved launch_approved redirect launched_row_order_position
        beta_row_order_position experimental_tools featured run_subject_set_completion_events ]
  end

  def build_resource_for_create(create_params)
    admin_allowed create_params, *admin_allowed_params

    if create_params.key?(:urls)
      urls, labels = UrlLabels.extract_url_labels(create_params[:urls])
      create_params[:url_labels] = labels
      create_params[:urls] = urls
    end

    if create_params.key?(:tags)
      create_params[:tags] = Tags::BuildTags.run!(api_user: api_user, tag_array: create_params[:tags])
    end

    add_user_as_linked_owner(create_params)

    super(create_params)
  end

  def build_update_hash(update_params, resource)
    admin_allowed update_params, *admin_allowed_params

    if update_params[:launch_approved]
      resource.launch_date ||= Time.zone.now
    end

    update_attributes = super(update_params, resource)
    update_attributes.except(:tags)
  end

  def new_items(resource, relation, value)
    construct_new_items(super(resource, relation, value), resource.id)
  end

  def construct_new_items(item_scope, project_id)
    Array.wrap(item_scope).map do |item|
      case item
      when Workflow
        WorkflowCopier.copy(item, project_id)
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
end
