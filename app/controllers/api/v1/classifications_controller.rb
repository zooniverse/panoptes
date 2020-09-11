require 'classification_lifecycle'

class Api::V1::ClassificationsController < Api::ApiController
  include JsonApiController::PunditPolicy

  class MissingParameter < StandardError; end


  skip_before_filter :require_login, only: :create
  require_authentication :show, :index, :destroy, :update, :incomplete, :project,
    scopes: [:classification]

  resource_actions :default

  schema_type :json_schema

  rescue_from JsonApiController::AccessDenied, with: :access_denied
  rescue_from MissingParameter, with: :unprocessable_entity

  before_action :filter_plural_subject_ids,
    only: [ :index, :gold_standard, :incomplete, :project ]

  def index
    DatabaseReplica.read('classification_serializer_data_from_replica') do
      super
    end
  end

  def create
    super { |classification| lifecycle(:create, classification) }
  end

  def update
    super
    controlled_resources.each { |resource| lifecycle(:update, resource) }
  end

  def gold_standard
    DatabaseReplica.read('classification_serializer_data_from_replica') do
      skip_policy_scope
      resources = Pundit.policy!(api_user, GoldStandardAnnotation).scope_for(:index)
      resources = resources.where(workflow_id: params[:workflow_id]) if params[:workflow_id]

      resources = resources.where(id: resource_ids) if resource_ids.present?

      gold_standard_page = GoldStandardAnnotationSerializer.page(
        params,
        resources,
        context
      )
      render json_api: gold_standard_page, generate_response_obj_etag: true
    end
  end

  def incomplete
    index
  end

  def project
    DatabaseReplica.read('classification_serializer_data_from_replica') do
      if params[:last_id] && !params[:project_id]
        raise MissingParameter, 'Project ID required if last_id is included'
      end

      resources = controlled_resources
      resources = resources.where(project_id: params[:project_id]) if params[:project_id]
      resources = resources.after_id(params[:last_id]) if params[:last_id]

      render json_api: serializer.page(params, resources, context),
             generate_response_obj_etag: true,
             add_http_cache: params[:http_cache]
    end
  end

  private

  def policy_options
    {scope_context: params}
  end

  def access_denied(exception)
    if %w(update destroy).include?(action_name) && resources_completed?
      not_authorized(StandardError.new(completed_error))
    else
      not_found(exception)
    end
  end

  def resources_completed?
    Classification.created_by(api_user.user)
    .complete
    .exists?(id: resource_ids)
  end

  def build_resource_for_create(create_params)
    super do |body_params, link_params|
      body_params[:user_id] = api_user.id
      body_params[:user_ip] = request_ip
      body_params[:subject_ids] = link_params.delete(:subjects)
      body_params[:workflow_version] = body_params[:metadata].delete(:workflow_version)
    end
  end

  def lifecycle(action, classification)
    if Panoptes.flipper[:classification_lifecycle_in_background].enabled?
      ClassificationLifecycle.queue(classification, action)
    else
      ClassificationLifecycle.perform(classification, action.to_s)
    end
  rescue Redis::CannotConnectError, Redis::TimeoutError, Timeout::Error => e
      Honeybadger.notify(e)
  end

  def completed_error
    if resource_ids.is_a?(Array)
      "#{controller_name} with ids='#{resource_ids.join(',')}' are complete"
    else
      "#{controller_name} with id='#{resource_ids}' is complete"
    end
  end

  def update_response
    serializer.resource(
      {},
      Classification.where(id: controlled_resources.first.id),
      context
    )
  end

  def context
    if %w(gold_standard incomplete project).include?(action_name)
      super.merge(url_suffix: action_name)
    else
      super
    end
  end

  # backwards compat for api subject filtering before moving to FilterHasMany
  def filter_plural_subject_ids
    if subject_ids = params.delete(:subject_ids)
      params[:subject_id] = subject_ids
    end
  end
end
