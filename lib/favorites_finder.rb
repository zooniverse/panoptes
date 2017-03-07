class FavoritesFinder
  def initialize(user, project, subject_ids)
    @user = user
    @project = project
    @subject_ids = subject_ids
  end

  def find_favorites
    return [] if @user.nil? || Panoptes.flipper[:skip_favorites_finder].enabled?
    fav_collections = @user.favorite_collections_for_project(@project)
    fav_collections.joins(:subjects).where(subjects: {id: @subject_ids}).pluck("subjects.id")
  end
end
