class Api::V1::ClassificationsController < Api::ApiController
  include JsonApiController

  skip_before_filter :require_login, only: :create
  doorkeeper_for :show, :index, :destory, :update, scopes: [:classification]
  resource_actions :default

  alias_method :classification, :controlled_resource

  METADATA_PARAMS = [:screen_resolution,
                     :started_at,
                     :finished_at,
                     :user_language,
                     :workflow_version,
                     :user_agent]

  private

  def build_resource_for_update(update_params)
    super
    lifecycle(:update)
    classification
  end

  def visible_scope
    Classification.visible_to(api_user)
  end

  def build_resource_for_create(create_params)
    super(create_params) do |create_params, link_params|
      link_params[:user] = api_user.user
      create_params[:user_ip] = request_ip
    end
    lifecycle(:create)
    classification
  end

  def cellect_host
    super(classification.workflow.id)
  end

  def lifecycle(action)
    lifecycle = ClassificationLifecycle.new(classification)
    lifecycle.validate_schema
    lifecycle.update_cellect(cellect_host)
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
end
