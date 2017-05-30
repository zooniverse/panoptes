class Api::V1::ProjectPagesController < Api::ApiController
  PARENT_RESOURCE = :project
  include Pages
end
