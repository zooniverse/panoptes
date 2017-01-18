class AddRecentsForeignKeys < ActiveRecord::Migration

  def change
    # remove all recents that have no traceable user in the classification
    # should have picked these up in the rake task to backfill :(
    Recent.where(user_id: nil)
      .joins(:classification)
      .where(classifications: { user_id: nil})
      .delete_all

    add_foreign_key :recents, :projects
    add_foreign_key :recents, :workflows
    add_foreign_key :recents, :users
  end
end
