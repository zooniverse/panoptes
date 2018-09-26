class CalculateProjectActivityWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform(project_id, period=nil)
    project = Project.find(project_id)
    Project.transaction do
      project_activity = 0
      project.workflows.each do |workflow|
        activity_period = WorkflowActivityPeriod.new(workflow, period)
        activity_count = activity_period.count
        workflow.update_columns(
          activity: activity_count,
          activity_classification_id: activity_period.earliest_activity_classification_id
        )
        project_activity += activity_count
      end
      project.update_columns activity: project_activity
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  class WorkflowActivityPeriod
    attr_reader :workflow, :period
    ACTIVITY_PERIOD = 24.hours.ago

    def initialize(workflow, period)
      @workflow = workflow
      @period = period || ACTIVITY_PERIOD
    end

    def count
      activity_scope.count
    end

    def earliest_activity_classification_id
      earliest_classification_id = activity_scope.select(:id).first
      earliest_classification_id&.id
    end

    private

    def activity_scope
      workflow_period_activity_scope.after_id(
        workflow.activity_classification_id
      )
    end

    def workflow_period_activity_scope
      workflow.classifications.where("created_at >= ?", period)
    end
  end
end
