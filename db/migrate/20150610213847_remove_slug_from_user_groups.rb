class RemoveSlugFromUserGroups < ActiveRecord::Migration
  def up
    remove_index :user_groups, :slug
    remove_column :user_groups, :slug
  end
  
  def down
    add_column :user_groups, :slug, :string
    add_index :user_groups, :slug, unique: true
  end
end
