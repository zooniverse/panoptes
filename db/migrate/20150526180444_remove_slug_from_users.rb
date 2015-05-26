class RemoveSlugFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :slug
    %i(projects collections user_groups).each do |table|
      add_index table, :slug, using: :btree
    end
  end
end
