class FavoritesFinder

  def self.find(user, project_id, subject_ids)
    if user.nil? || Panoptes.flipper[:skip_favorites_finder].enabled?
      return []
    end

    fav_collections = user.favorite_collections_for_project(project_id)

binding.pry
    CollectionsSubject.where(collection_id: fav_collections.select(:id)).pluck("subject_id")
  end
end
