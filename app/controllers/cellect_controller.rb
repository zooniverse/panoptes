class CellectController < ApplicationController
  before_filter :html_to_json_override

  def workflows
    respond_to do |format|
      format.json do
        render json: { workflow_ids: all_cellect_workflow_ids.as_json }
      end
    end
  end

  private

  def launched_workflows
    Workflow
      .joins(:project)
      .where("projects.launch_approved IS TRUE")
      .select(:id, :use_cellect)
  end

  def workflow_ids_using_cellect
    launched_workflows.collect do |w|
      w.using_cellect? ? w.id : nil
    end.compact
  end

  def all_cellect_workflow_ids
     workflow_ids_using_cellect | Workflow.using_cellect.pluck(:id)

  def html_to_json_override
    request.format = :json if request.format == :html
  end
end
