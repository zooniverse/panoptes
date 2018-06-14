class Api::V1::SubjectWorkflowStatusesController < Api::ApiController
  include JsonApiController::LegacyPolicy

  resource_actions :index, :show
end
