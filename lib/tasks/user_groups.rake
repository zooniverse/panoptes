# frozen_string_literal: true

namespace :user_groups do
    desc 'Backfill stats_visibility column default in batches'
    task backfill_stats_visibility_column_default: :environment do
      UserGroup.where(stats_visibility: nil).select(:id).find_in_batches do |user_group|
        user_group_ids_to_update = user_group.map(&:id)
        UserGroup.where(id: user_group_ids_to_update).update_all(stats_visibility: 0)
      end
    end
end