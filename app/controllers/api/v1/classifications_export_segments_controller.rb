class Api::V1::ClassificationsExportSegmentsController < Api::ApiController
  require_authentication :all, scopes: [:project]

  resource_actions :default

  schema_type :strong_params

  allowed_params :create, links: [:project, :workflow, :first_classification, :last_classification]
  allowed_params :update, links: [:project, :workflow, :first_classification, :last_classification]

  def create
    classifications_export_segments = ClassificationsExportSegment.transaction do
      Array.wrap(params[:classifications_export_segments]).map do |segment_params|
        segment_params[:links] ||= {}
        segment_params[:links][:project] = params[:project_id]
        ClassificationsExportSegments::Create.with(api_user: api_user).run!(segment_params)
      end
    end

    created_resource_response(classifications_export_segments)
  end

  def controlled_resources
    @controlled_resouces ||= super.where(project: params[:project_id])
  end

  protected

  def build_resource_for_create(create_params)
    create_params[:links] ||= {}
    create_params[:links][:project] = params[:project_id]
    super create_params
  end

  def link_header(resource)
    resource = resource.first
    send(:"api_project_#{ resource_name }_url", id: resource.id, project_id: resource.project_id)
  end
end
