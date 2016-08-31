class CellectController < ApplicationController
  before_filter :html_to_json_override

  EXPIRY = 10.minutes.freeze

  def workflows
    respond_to do |format|
      format.json do
        cache_response(EXPIRY)
        render json: { workflows: all_cellect_workflows.as_json }
      end
    end
  end

  def subjects
    respond_to do |format|
      format.json do
        expires_in 1.minute, public: true
        render json: { subjects: cellect_workflow_subjects.as_json }
      end
    end
  end

  private

  def launched_workflows
    Workflow
      .joins(:project)
      .where("projects.launch_approved IS TRUE")
      .order(:id)
      .select(:id, :subject_selection_strategy, :pairwise, :prioritized, :grouped)
  end

  def workflows_using_cellect
    launched_workflows.collect do |w|
      w.using_cellect? ? w.slice(:id, :pairwise, :prioritized, :grouped) : nil
    end.compact
  end

  def all_cellect_workflows
    cache_key = "#{Rails.env}#all_cellect_workflows"
    Rails.cache.fetch(cache_key, expires_in: EXPIRY) do
      workflows_using_cellect
    end
  end

  def cellect_workflow_subjects
    if workflow = cellect_workflow_from_param
      SetMemberSubject
        .non_retired_for_workflow(workflow)
        .select('set_member_subjects.subject_id as id', :priority, :subject_set_id)
    else
      []
    end
  end

  def cellect_workflow_from_param
    workflow = launched_workflows.find_by_id params[:workflow_id]
    workflow if workflow&.using_cellect?
  end

  def html_to_json_override
    request.format = :json if request.format == :html
  end

  def cache_response(expiration_time)
    if Panoptes.flipper[:cellect_controller_caching].enabled?
      expires_in expiration_time, public: true
    end
  end
end
