class RemoveSlugFromUserGroups < ActiveRecord::Migration
  def change
    remove_column :user_groups, :slug, :string
  end
end
