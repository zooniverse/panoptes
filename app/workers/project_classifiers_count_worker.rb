class ProjectClassifiersCountWorker
  include Sidekiq::Worker

  sidekiq_options congestion: {
    interval: 15,
    max_in_interval: 1,
    min_delay: 0,
    reject_with: :reschedule,
    key: ->(project_id) {
      "project_#{project_id}_classifiers_count_worker"
    }
  }

  def perform(project_id)
    project = Project.find(project_id)
    counter = ProjectCounter.new(project)
    project.update_column(:classifiers_count, counter.volunteers)
  end
end
