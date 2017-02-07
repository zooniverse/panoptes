class AddRecentsForeignKeys < ActiveRecord::Migration

  def change
    add_foreign_key :recents, :projects
    add_foreign_key :recents, :workflows
    add_foreign_key :recents, :users
  end
end
