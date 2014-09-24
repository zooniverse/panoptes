class Api::V1::WorkflowsController < Api::ApiController
  include JsonApiController
  
  before_filter :require_login, only: [:create, :update, :destroy]
  doorkeeper_for :update, :create, :delete, scopes: [:project]
  access_control_for :create, :update, :destroy, resource_class: Workflow

  resource_actions :default

  allowed_params :create, :pairwise, :grouped, :prioritized, :name,
    :primary_language, tasks: [:key, :question, :type, :answers],
    links: [:project, subject_sets: []]

  allowed_params :update, :pairwise, :grouped, :prioritized, :name,
    tasks: [:key, :question, :type, :answers], links: [subject_sets: []]

  alias_method :workflow, :controlled_resource

  def show
    load_cellect
    super
  end

  private

  def load_cellect
    return unless api_user.logged_in?
    Cellect::Client.connection.load_user(**cellect_params)
  end

  def cellect_params
    {
      host: cellect_host(params[:id]),
      user_id: api_user.id,
      workflow_id: params[:id]
    }
  end
end
