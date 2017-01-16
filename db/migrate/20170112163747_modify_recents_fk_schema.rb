class ModifyRecentsFkSchema < ActiveRecord::Migration

  def change
    %i(project_id workflow_id user_id user_group_id).each do |col|
      add_column :recents, col, :integer
    end
  end
end
