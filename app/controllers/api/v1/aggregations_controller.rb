# frozen_string_literal: true

class Api::V1::AggregationsController < Api::ApiController
  include JsonApiController::PunditPolicy

  require_authentication :index, :show, :update, :create, scopes: [:project]
  resource_actions :index, :show, :create, :update
  schema_type :json_schema

  def create
    workflow = Workflow.find(create_params['links']['workflow'])
    project_id = workflow.project.id
    create_params['links']['project'] = project_id
    response = AggregationClient.new.send_aggregation_request(
      project_id,
      workflow.id,
      create_params['links']['user']
    )
    super do |agg|
      agg.update({ task_id: response.body[:task_id], status: 'pending' })
    end
  rescue AggregationClient::ConnectionError
    json_api_render(:service_unavailable, 'The aggregation service is unavailable or not responding')
  end
end
