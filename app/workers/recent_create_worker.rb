class RecentCreateWorker
  include Sidekiq::Worker

  def perform(classification_id)
    classification = Classification.find(classification_id)
    Recent.create_from_classification(classification)

    # TODO: move this to the Recent class
    # TODO: provide a constant / env var to modify
    #       the capped collection size
    # find the latest 50(default) classifications
    # and mark any with an id > the last one
    # for removal and thus cleanup
    user_project_recent_scope = Recent.where(
      project_id: classification.project_id,
      user_id: classification.user_id
    ).order(id: 'ASC')
    last_id = user_project_recent_scope.limit(1).pluck(:id)
    user_project_recent_scope.where("id > ?", last_id).update_all(mark_remove: true)
  end
end
