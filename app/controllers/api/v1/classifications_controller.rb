class Api::V1::ClassificationsController < Api::ApiController
  include JsonApiController
  
  doorkeeper_for :show, :index, :destory, :update, scopes: [:classification]
  access_control_for :update, :destroy, resource_class: Classification

  resource_actions :default

  request_template :create, :completed,
    annotations: [:key, :value, :started_at, :finished_at, :user_agent],
    links: [:project, :workflow, :set_member_subject, :subject]

  request_template :update, :completed,
    annotations: [:key, :value, :started_at, :finished_at, :user_agent]

  def create
    classification = ActiveRecord::Base.transaction do 
      create_resource(create_params)
    end
    if classification.save!
      
      update_cellect(classification) 
      created_resource_response(classification)
    end
  end

  private

  def visible_scope
    Classification.visible_to(api_user)
  end

  def create_resource(create_params)
    create_params[:links][:user] = api_user.user
    create_params[:user_ip] = request_ip
    classification = super(create_params)
    classification
  end

  def update_cellect(classification)
    Cellect::Client.connection
      .add_seen(user_id: classification.user_id,
                workflow_id: classification.workflow_id,
                subject_id: classification.set_member_subject.id,
                host: cellect_host(classification.workflow_id))
  end
end
