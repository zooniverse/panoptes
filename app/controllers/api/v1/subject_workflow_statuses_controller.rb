class Api::V1::SubjectWorkflowStatusesController < Api::ApiController
  include RoleControl::RoledController
  resource_actions :index, :show
end
