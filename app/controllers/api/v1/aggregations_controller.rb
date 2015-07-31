class Api::V1::AggregationsController < Api::ApiController
  doorkeeper_for :index, scopes: [:project], unless: :public_workflows?
  doorkeeper_for :create, :update, :show, scopes: [:project]
  resource_actions :create, :update, :show, :index
  schema_type :json_schema

  before_action :filter_by_subject_set, only: :index

  def scope_context
    super.tap do |context|
      if public_workflows?
        context.merge!({ public_workflow_ids: workflow_ids })
      end
    end
  end

  private

  def filter_by_subject_set
    subject_set_ids = params.delete(:subject_set_id).try(:split, ',')
    unless subject_set_ids.blank?
      @controlled_resources = controlled_resources
        .joins(workflow: :subject_sets)
        .where(workflows: { subject_set_id: subject_set_ids } )
    end
  end

  def workflow_ids
    @workflow_ids ||= params.slice(:workflow_id, :workflow_ids)
      .values.join(",").split(',')
  end

  def public_workflows?
    return @public_workflows if @public_workflows
    @public_workflows = false
    unless workflow_ids.blank?
      public_count = Workflow.where(id: workflow_ids)
        .where("aggregation ->> 'public' = 'true'").count
      @public_workflows = public_count == workflow_ids.size
    end
  end
end
