class ProjectCopyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high, lock: :until_executed

  def perform(project_id, user_id)
    ProjectCopier.new(project_id, user_id).copy
  rescue ActiveRecord::RecordNotFound
  end
end
