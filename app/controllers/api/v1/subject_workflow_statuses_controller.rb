class Api::V1::SubjectWorkflowStatusesController < Api::ApiController
  include JsonApiController::PunditPolicy

  resource_actions :index, :show
end
