# frozen_string_literal: true

class AddStatsVisibilityToUserGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :user_groups, :stats_visibility, :integer
    # defaulting to restricted stats_visibility view (where members can view aggregate stats but only admins can view detailed stats)
    change_column_default :user_groups, :stats_visibility, from: nil, to: 0
  end
end
