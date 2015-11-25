class Api::V1::AggregationsController < Api::ApiController

  require_authentication :create, :update, scopes: [:project]
  resource_actions :create, :update, :show, :index
  schema_type :json_schema
  before_action :filter_by_subject_set, only: :index

  private

  def filter_by_subject_set
    subject_set_ids = params.delete(:subject_set_id).try(:split, ',')
    unless subject_set_ids.blank?
      @controlled_resources = controlled_resources
        .joins(workflow: :subject_sets)
        .where(workflows: { subject_set_id: subject_set_ids } )
    end
  end
end
