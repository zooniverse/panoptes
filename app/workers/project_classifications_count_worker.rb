class ProjectClassificationsCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

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
    #temp fix to clear the counters
    return nil

    project = Project.find(project_id)
    project.workflows.map do |workflow|
      counter = WorkflowCounter.new(workflow)
      workflow.update_column(:classifications_count, counter.classifications)
    end
    counter = ProjectCounter.new(project)
    project.update_column(:classifications_count, counter.classifications)
  end
end
