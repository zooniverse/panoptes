namespace :recents do
  desc 'Backfill mark_remove column default in batches'
  task backfill_recents_mark_remove_column_default: :environment do
    Recent.where(mark_remove: nil).select(:id).find_in_batches do |recents|
      recent_ids_to_update = recents.map(&:id)
      Recent.where(id: recent_ids_to_update).update_all(mark_remove: false)
    end
  end
end
