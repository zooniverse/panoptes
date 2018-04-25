class Api::V1::ProjectPagesController < Api::ApiController
  include RoleControl::RoledController
  PARENT_RESOURCE = :project
  include Pages
end
