class Api::V1::ClassificationsExportSegmentsController < Api::ApiController
  require_authentication :all, scopes: [:project]

  before_action :require_access_to_project, only: [:create]

  resource_actions :default

  def create
    classifications_export_segments = ClassificationsExportSegment.transaction do
      Array.wrap(params[:classifications_export_segments]).map do |segment_params|
        ClassificationsExportSegments::Create.with(api_user: api_user, project: @project).run!(segment_params)
      end
    end

    created_resource_response(classifications_export_segments)
  end

  def controlled_resources
    @controlled_resouces ||= super.where(project: params[:project_id])
  end

  protected

  def require_access_to_project
    @project = Project.scope_for(:update, api_user, {}).where(id: params[:project_id]).first

    unless @project
      raise Api::Unauthorized
    end
  end

  def link_header(resource)
    resource = resource.first
    send(:"api_project_#{ resource_name }_url", id: resource.id, project_id: resource.project_id)
  end
end
