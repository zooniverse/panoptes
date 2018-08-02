class ProjectClassificationsCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  sidekiq_options congestion: {
    interval: 60,
    max_in_interval: 1,
    min_delay: 60,
    reject_with: :reschedule,
    key: ->(project_id) {
      "project_#{project_id}_classifications_count_worker"
    }
  }

  sidekiq_options lock: :until_executed

  def perform(project_id)
    project = Project.find(project_id)
    counter = ProjectCounter.new(project)
    project.update_column(:classifications_count, counter.classifications)
  end
end
