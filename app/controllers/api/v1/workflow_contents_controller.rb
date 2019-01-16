class Api::V1::WorkflowContentsController < Api::ApiController
  include JsonApiController::PunditPolicy

  require_authentication :all, scopes: [:project]
  resource_actions :default
  schema_type :json_schema

  def index
    head :gone
  end

  def show
    head :gone
  end

  def create
    head :gone
  end

  def update
    head :gone
  end

  def destroy
    head :gone
  end
end
