class Api::V1::ClassificationsController < Api::ApiController
  skip_before_filter :require_login, only: :create
  doorkeeper_for :show, :index, :destroy, :update, scopes: [:classification]
  
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
  
  
  def build_resource_for_update(update_params)
    classification = super
    lifecycle(:update, classification)
    classification
  end

  def sms_ids_from_links(link_params)
    sms = if ids = link_params.delete(:set_member_subjects)
      SetMemberSubject.select(:id).find(ids)
    elsif ids = link_params.delete(:subjects)
      SetMemberSubject.joins(:subject_set)
        .where(subject_sets: {workflow_id: link_params[:workflow]})
        .select(:id)
        .find_by(subject_id: ids)
    end
    sms.try(:map, &:id) || [sms.id]
  end

  def build_resource_for_create(create_params)
    classification = super(create_params) do |create_params, link_params|
      link_params[:user] = api_user.user
      create_params[:user_ip] = request_ip
      create_params[:set_member_subject_ids] = sms_ids_from_links(link_params)
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
                                                 set_member_subjects: [],
                                                 subjects: []] ]
    params.require(:classifications).permit(param_set)
  end

  def update_params
    params.require(:classifications).permit(create_update_params)
  end

  def completed_error
    if resource_ids.is_a?(Array)
      "#{controller_name} with ids='#{resource_ids.join(',')}' are complete"
    else
      "#{controller_name} with id='#{resource_ids}' is complete"
    end
  end
end
