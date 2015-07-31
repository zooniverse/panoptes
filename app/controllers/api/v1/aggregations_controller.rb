class Api::V1::AggregationsController < Api::ApiController

  doorkeeper_for :index, :show, scopes: [:project], unless: :public_access?
  doorkeeper_for :create, :update, scopes: [:project]
  resource_actions :create, :update, :show, :index
  schema_type :json_schema

  skip_before_action :check_controller_resources, only: :show,  if: :public_resource_workflow?

  before_action :filter_by_subject_set, only: :index
  before_action :filter_by_public_workflows, only: :index, if: :public_workflows?
  before_action :filter_by_public_resource_workflow, only: :show, if: :public_resource_workflow?

  private

  def filter_by_subject_set
    subject_set_ids = params.delete(:subject_set_id).try(:split, ',')
    unless subject_set_ids.blank?
      @controlled_resources = controlled_resources
        .joins(workflow: :subject_sets)
        .where(workflows: { subject_set_id: subject_set_ids } )
    end
  end

  def filter_by_public_workflows
    @controlled_resources = Aggregation.joins(:workflow).where(workflow_id: workflow_ids)
  end

  def filter_by_public_resource_workflow
    @controlled_resources = Aggregation.where(id: resource_ids)
  end

  def public_access?
    public_resource_workflow? || public_workflows?
  end

  def workflow_ids
    @workflow_ids ||= params.slice(:workflow_id, :workflow_ids)
      .values.join(",").split(',')
  end

  def public_workflows?
    return @public_workflows if @public_workflows
    @public_workflows = false
    unless workflow_ids.blank?
      public_count = public_workflow_scope(Workflow.where(id: workflow_ids)).count
      @public_workflows = public_count == workflow_ids.size
    end
  end

  def public_resource_workflow?
    return @public_resource_workflow if @public_resource_workflow
    @public_resource_workflow = false
    if resource_ids
      workflow_scope = Workflow
        .joins("LEFT OUTER JOIN aggregations ON aggregations.workflow_id = workflows.id")
        .where('aggregations.id = ?', resource_ids)
      @public_resource_workflow = public_workflow_scope(workflow_scope).exists?
    end
  end

  def public_workflow_scope(scope)
    scope.where("workflows.aggregation ->> 'public' = 'true'")
  end
end
