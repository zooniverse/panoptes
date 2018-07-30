class ProjectCopyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(project_id, user_id)
    ProjectCopyWorker.copy(project_id, user_id)
  end
end