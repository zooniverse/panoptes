class RecentsCleanupWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default,
                  retry: 0,
                  congestion: {
                    interval: 1.hour,
                    max_in_interval: 1,
                    reject_with: :cancel
                  }

  def perform
    # Delete all older than 14 days
    Recent.where('created_at < ?', 14.days.ago).in_batches(of: 5000).delete_all

    # Identify users active in the past 2 hours
    recently_active_user_ids = Recent.where('created_at > ?', 2.hours.ago)
                                     .distinct
                                     .pluck(:user_id)

    # Delete all but the 20 newest recents for each recently active user
    recently_active_user_ids.each do |user_id|
      next unless Recent.where(user_id: user_id).count > 20

      ids_to_keep = Recent.where(user_id: user_id)
                          .order(created_at: :desc)
                          .limit(20)
                          .pluck(:id)

      Recent.where(user_id: user_id)
            .where.not(id: ids_to_keep)
            .delete_all
    end
  end
end