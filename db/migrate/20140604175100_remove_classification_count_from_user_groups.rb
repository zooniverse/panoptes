class RemoveClassificationCountFromUserGroups < ActiveRecord::Migration
  def change
    remove_column :user_groups, :classification_count
  end
end
