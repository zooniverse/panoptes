class Api::V1::ProjectPagesController < Api::ApiController
  include Pages

  require_authentication :update, :create, :destroy, scopes: [:project]

  def parent_resource
    :project
  end

  def resource_id
    params[:project_id]
  end

  def resource_name
    "project_page"
  end
end
