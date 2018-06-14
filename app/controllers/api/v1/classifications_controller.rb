require 'classification_lifecycle'

class Api::V1::ClassificationsController < Api::ApiController
  include JsonApiController::LegacyPolicy

  skip_before_filter :require_login, only: :create
  require_authentication :show, :index, :destroy, :update, :incomplete, :project,
    scopes: [:classification]

  resource_actions :default

  schema_type :json_schema

  rescue_from JsonApiController::AccessDenied, with: :access_denied

  before_action :filter_plural_subject_ids,
    only: [ :index, :gold_standard, :incomplete, :project ]

  def create
    super { |classification| lifecycle(:create, classification) }
  end

  def update
    super
    controlled_resources.each { |resource| lifecycle(:update, resource) }
  end

  def gold_standard
    gold_standard_page = GoldStandardAnnotationSerializer.page(
      params,
      controlled_resources,
      context
    )
    render json_api: gold_standard_page, generate_response_obj_etag: true
  end

  def incomplete
    index
  end

  def project
    index
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
