class Api::V1::ClassificationsController < Api::ApiController
  skip_before_filter :require_login, only: :create
  doorkeeper_for :show, :index, :destroy, :update, scopes: [:classification]

  resource_actions :default
  
  schema_type :json_schema

  rescue_from RoleControl::AccessDenied, with: :access_denied

  def create
    super { |classification| lifecycle(:create, classification) }
  end

  def update
    super { |classification| lifecycle(:update, classification) }
  end

  private

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
    classification = super(create_params) do |create_params, link_params|
      link_params[:user] = api_user.user
      create_params[:user_ip] = request_ip
      create_params[:subject_ids] = link_params.delete(:subjects)
    end
    classification
  end

  def cellect_host(classification)
    super(classification.workflow.id)
  end

  def lifecycle(action, classification)
    lifecycle = ClassificationLifecycle.new(classification)
    lifecycle.update_cellect(cellect_host(classification))
    lifecycle.queue(action)
  end

  def completed_error
    if resource_ids.is_a?(Array)
      "#{controller_name} with ids='#{resource_ids.join(',')}' are complete"
    else
      "#{controller_name} with id='#{resource_ids}' is complete"
    end
  end
end
