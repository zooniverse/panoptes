class Api::V1::TutorialsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include SyncResourceTranslationStrings

  require_authentication :update, :create, :destroy, scopes: [:project]

  resource_actions :default

  schema_type :json_schema

  before_action :set_language_if_missing, only: [:index]

  protected

  def controlled_resources
    @controlled_resources ||= super

    if params[:workflow_id]
      @controlled_resources = @controlled_resources.joins(:workflow_tutorials).where(workflow_tutorials: {workflow_id: params[:workflow_id]})
    end

    if params[:kind]
      @controlled_resources = @controlled_resources.where(kind: params[:kind])
    end

    @controlled_resources
  end

  def set_language_if_missing
    params[:language] ||= "en"
  end
end
