namespace :collections do
  desc 'Backfill subjects_count on collections'
  task backfill_subjects_count: :environment do
    Collection.in_batches(of: 1_000) do |batch|
      collection_ids = batch.pluck(:id)

      counts = CollectionsSubject
               .where(collection_id: collection_ids)
               .group(:collection_id)
               .count

      collections_to_update = collection_ids.map do |id|
        [id, counts[id] || 0]
      end

      collections_to_update.each do |id, count|
        Collection.where(id: id)
                  .update_all(subjects_count: count)
      end
    end
  end
end
