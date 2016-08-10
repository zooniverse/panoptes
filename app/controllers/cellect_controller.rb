class CellectController < ApplicationController
  def workflows
    respond_to do |format|
      format.json do
        cellect_workflows = Workflow.all
        render json: { workflow_ids: cellect_workflows.pluck(:id).as_json }
      end
    end
  end
end
