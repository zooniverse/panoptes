class AddUniqueIndexToSlug < ActiveRecord::Migration
  def change
    remove_index :user_groups, :slug
    add_index :user_groups, :slug, unique: true
  end
end
