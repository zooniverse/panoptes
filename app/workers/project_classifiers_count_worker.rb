class ProjectClassifiersCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  sidekiq_options congestion: {
    interval: 60,
    max_in_interval: 1,
    min_delay: 0,
    reject_with: :reschedule,
    key: ->(project_id) { "project_#{project_id}_classifiers_count_worker" }
  }

  sidekiq_options lock: :until_executing

  def perform(project_id)
    project = Project.find(project_id)
    counter = ProjectCounter.new(project)
    project.update_column(:classifiers_count, counter.volunteers)
  end
end
