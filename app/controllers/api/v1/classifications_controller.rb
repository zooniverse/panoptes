require 'classification_lifecycle'

class Api::V1::ClassificationsController < Api::ApiController
  skip_before_filter :require_login, only: :create
  require_authentication :show, :index, :destroy, :update, :incomplete, :project,
    scopes: [:classification]

  resource_actions :default

  schema_type :json_schema

  before_action :filter_by_subject_id,
    only: [ :index, :gold_standard, :incomplete, :project ]

  rescue_from RoleControl::AccessDenied, with: :access_denied

  def create
    super { |classification| lifecycle(:create, classification) }
  end

  def update
    super { |classification| lifecycle(:update, classification) }
  end

  def gold_standard
    index
  end

  def incomplete
    index
  end

  def project
    index
  end

  private

  def filter_by_subject_id
    subject_ids = (params.delete(:subject_ids) || params.delete(:subject_id)).try(:split, ',')
    unless subject_ids.blank?
      @controlled_resources = controlled_resources
      .joins(:subjects)
      .where(subjects: {id: subject_ids})
    end
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
      .merge(Classification.complete)
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
    ClassificationLifecycle.new(classification).queue(action)
  rescue Redis::CannotConnectError => e
    Honeybadger.notify(e)
  end

  def completed_error
    if resource_ids.is_a?(Array)
      "#{controller_name} with ids='#{resource_ids.join(',')}' are complete"
    else
      "#{controller_name} with id='#{resource_ids}' is complete"
    end
  end
end
