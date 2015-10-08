class Api::V1::TutorialsController < Api::ApiController
  doorkeeper_for :update, :create, :destroy, scopes: [:project]

  resource_actions :default

  schema_type :json_schema

  before_filter :set_language_from_header, only: [:index]
  before_filter :filter_by_project, only: [:index]

  protected

  def filter_by_project
    if project_id = params.delete(:project_id).try(:to_i)
      @controlled_resources = controlled_resources.joins(:workflow).where(workflows: { project_id: project_id })
    end
  end

  def set_language_from_header
    params[:language] = "en"
  end
end
