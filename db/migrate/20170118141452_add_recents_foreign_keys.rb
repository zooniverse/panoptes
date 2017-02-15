class AddRecentsForeignKeys < ActiveRecord::Migration

  def change
    # FAILED TO WORK ON PRODUCTION.
    # Failed to get a lock on the table to be able to add the FK.
    # This migration was retroactively commented out so that it'll "work" on production.
    # We then added a migration later on to make staging have an equal schema to production again

    # remove_deleted_project_recents
    # add_foreign_key :recents, :projects

    # remove_deleted_workflow_recents
    # add_foreign_key :recents, :workflows

    # remove_deleted_user_recents
    # add_foreign_key :recents, :users
  end

  # def remove_deleted_project_recents
  #   Recent
  #     .joins("LEFT OUTER JOIN projects ON projects.id = recents.project_id")
  #     .where("recents.id IS NOT NULL AND projects.id IS NULL")
  #     .delete_all
  # end

  # def remove_deleted_workflow_recents
  #   Recent
  #     .joins("LEFT OUTER JOIN workflows ON workflows.id = recents.workflow_id")
  #     .where("recents.id IS NOT NULL AND workflows.id IS NULL")
  #     .delete_all
  # end

  # def remove_deleted_user_recents
  #   Recent
  #     .joins("LEFT OUTER JOIN users ON users.id = recents.user_id")
  #     .where("recents.id IS NOT NULL AND users.id IS NULL")
  #     .delete_all
  # end
end
