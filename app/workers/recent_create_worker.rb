class RecentCreateWorker
  include Sidekiq::Worker

  def perform(classification_id)
    classification = Classification.find(classification_id)
    recents = Recent.create_from_classification(classification)
    latest_recent_id = recents.last.id

    # TODO: move this to the Recent class
    # TODO: provide a constant / env var to modify
    #       the capped collection size
    # find the most recent 50(default) classifications
    # and mark any with an id < the last one
    # for removal and thus cleanup
    user_project_recent_scope = Recent.where(
      project_id: classification.project_id,
      user_id: classification.user_id
    ).order(id: 'DESC')
    # ensure we specify the ID here as the recents table can be big
    # use the recent id in the creation above to seed the search point
    # in the recents table
    oldest_allowed_recent_id = user_project_recent_scope.where('id < ?', latest_recent_id).limit(1).pluck(:id)
    # then seed the update_all mark query to search the recents table
    # by the capped collection id offset
    user_project_recent_scope.where('id < ?', oldest_allowed_recent_id).update_all(mark_remove: true)
  end
end
