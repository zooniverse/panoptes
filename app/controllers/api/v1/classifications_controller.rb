class Api::V1::ClassificationsController < Api::ApiController
  skip_before_filter :require_login, only: :create
  doorkeeper_for :show, :index, :destroy, :update, scopes: [:classification]
  setup_access_control_for_user!
  
  resource_actions :default

  rescue_from RoleControl::AccessDenied, with: :access_denied

  METADATA_PARAMS = [:screen_resolution,
                     :started_at,
                     :finished_at,
                     :user_language,
                     :workflow_version,
                     :user_agent]

  private

  def access_denied(exception)
    case action_name
    when "update", "destroy"
      if Classification.created_by(api_user.user)
          .where(id: resource_ids, completed: true).exists?
        error = StandardError.new(completed_error)
        not_authorized(error)
      else
        not_found(exception)
      end
    else
      not_found(exception)
    end
  end
  
  def build_resource_for_update(update_params)
    classification = super
    lifecycle(:update, classification)
    classification
  end

  def build_resource_for_create(create_params)
   classification = super(create_params) do |create_params, link_params|
      link_params[:user] = api_user.user
      create_params[:user_ip] = request_ip
    end
    lifecycle(:create, classification)
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

  def annotation_params
    params[:classifications][:annotations].map(&:keys)
  end

  def create_update_params
    [ :completed,
      :gold_standard,
      metadata: METADATA_PARAMS,
      annotations: annotation_params ]
  end

  def create_params
    param_set = create_update_params | [ links: [:project,
                                                 :workflow,
                                                 :set_member_subject] ]
    params.require(:classifications).permit(param_set)
  end

  def update_params
    params.require(:classifications).permit(create_update_params)
  end

  def completed_error
    if resource_ids.length == 1
      "Classification with id='#{resource_ids.first}' is complete"
    else
      "Classifications with ids='#{resource_ids.join(',')}' are complete"
    end
  end
end
