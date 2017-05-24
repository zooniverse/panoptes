class Api::V1::ProjectPagesController < Api::ApiController
  PARENT_RESOURCE = :project.freeze
  include Pages
end
