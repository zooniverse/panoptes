class UserProjectPreferencesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high, lock: :until_executed

  def perform(user_id, project_id)
    user = User.find(user_id)
    project = Project.find(project_id)

    UserProjectPreferences::FindOrCreate.run!(
      user: user,
      project: project
    )
  rescue ActiveRecord::RecordNotFound
  end
end
