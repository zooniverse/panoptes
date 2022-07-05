class SubjectSelectionStrategiesController < ApplicationController
  before_filter :html_to_json_override

  EXPIRY = 10.minutes.freeze
  SELECT_COLS = %i(
    id subject_selection_strategy pairwise prioritized grouped updated_at
  ).freeze

  def workflows
    respond_to do |format|
      format.json do
        cache_response(EXPIRY)
        render json: { workflows: workflows_response.as_json }
      end
    end
  end

  def subjects
    respond_to do |format|
      format.json do
        expires_in 1.minute, public: true
        render json: { subjects: subjects_response.as_json }
      end
    end
  end

  private

  def workflows_response
    cache_key = "#{Rails.env}#workflows_with_subject_selection_strategy/#{strategy}"

    Rails.cache.fetch(cache_key, expires_in: EXPIRY) do
      workflows_for_strategy.collect do |w|
        w.slice(:id, :pairwise, :prioritized, :grouped)
      end
    end
  end

  def subjects_response
    if workflow = workflows_for_strategy.find_by_id(params[:workflow_id])
      SetMemberSubject
        .non_retired_for_workflow(workflow)
        .select('set_member_subjects.subject_id as id', :priority, :subject_set_id)
    else
      []
    end
  end

  def workflows_for_strategy
    Workflow
      .joins(:project)
      .where("projects.launch_approved IS TRUE")
      .where(subject_selection_strategy: strategy)
      .order(:id)
      .select(SELECT_COLS)
  end

  def strategy
    Workflow.subject_selection_strategies[params.fetch(:strategy)]
  end

  def html_to_json_override
    request.format = :json if request.format == :html
  end

  def cache_response(expiration_time)
    if Flipper.enabled?(:cellect_controller_caching)
      expires_in expiration_time, public: true
    end
  end
end
