class RecentSweeperWorker
  include Sidekiq::Worker

  include Sidetiq::Schedulable

  sidekiq_options queue: :data_low

  recurrence { hourly }

  def perform
    # https://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-in_batches
    # move this method to in_batches when migrating past rails 4
    recent_ids_to_delete = Recent.where(mark_remove: true).select(:id)
    recent_ids_to_delete.find_in_batches do |recents|
      Recent.where(id: recents).destroy_all
    end
  end
end
