class CalculateProjectActivityWorker
  include Sidekiq::Worker

  def perform(project_id)
    Project.transaction do
      project = Project.find(project_id)
      project_activity = 0
      project.workflows.all.each do |workflow|
        activity_count = workflow_activity(workflow)
        workflow.update! activity: activity_count
        project_activity += activity_count
      end
      project.update! activity: project_activity
    end
  end

  def workflow_activity(workflow, period=24.hours.ago)
    workflow.classifications.where("created_at >= ?", period).count
  end
end
