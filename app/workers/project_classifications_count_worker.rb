class ProjectClassificationsCountWorker
  include Sidekiq::Worker

  sidekiq_options congestion: {
    interval: 60,
    max_in_interval: 1,
    min_delay: 0,
    reject_with: :cancel,
    key: ->(project_id) {
      "project_#{project_id}_classifications_count_worker"
    }
  }

  def perform(project_id)
    project = Project.find(project_id)

    counts = project.workflows.map do |workflow|
      count = workflow.subject_workflow_counts.sum(:classifications_count)
      workflow.update_column :classifications_count, count
      count
    end

    project.update_column(:classifications_count, counts.sum)
  end
end
