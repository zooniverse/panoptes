class CalculateProjectActivityWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform(project_id)
    project = Project.find(project_id)
    Project.transaction do
      project_activity = 0
      project.workflows.each do |workflow|
        activity_count = workflow_activity(workflow)
        workflow.update_columns activity: activity_count
        project_activity += activity_count
      end
      project.update_columns activity: project_activity
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def workflow_activity(workflow, period=24.hours.ago)
    workflow.classifications.where("created_at >= ?", period).count
  end
end
