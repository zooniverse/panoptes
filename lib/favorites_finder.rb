class FavoritesFinder

  def self.find(user, project_id, subject_ids)
    return [] if user.nil? || Flipper.enabled?(:skip_favorites_finder)

    fav_collections = user.favorite_collections_for_project(project_id)

    fav_collections
    .joins(:subjects)
    .where(subjects: {id: subject_ids})
    .pluck("subjects.id")
  end
end
