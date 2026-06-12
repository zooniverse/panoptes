# frozen_string_literal: true

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
    # Delete all older than 90 days
    Recent.where('created_at < ?', 90.days.ago).in_batches(of: 5000).delete_all

    # Identify users active in the past 2 hours
    recently_active_pairs = Recent.where('created_at > ?', 2.hours.ago)
                                  .distinct
                                  .pluck(:user_id, :project_id)

    # Clean up any recents over 20 per user/project for recently active users
    recently_active_pairs.each do |user_id, project_id|
      scope = Recent.where(user_id: user_id, project_id: project_id)

      next unless scope.count > 20

      ids_to_keep = scope.order(created_at: :desc)
                         .limit(20)
                         .pluck(:id)

      scope.where.not(id: ids_to_keep).delete_all
    end
  end
end
