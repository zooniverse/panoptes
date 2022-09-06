# frozen_string_literal: true

module RateLimitDumpWorker
  extend ActiveSupport::Concern

  included do
    sidekiq_options congestion:
      {
        interval: Panoptes::RateLimitDumpWorker.interval,
        max_in_interval: Panoptes::RateLimitDumpWorker.max_in_interval,
        min_delay: Panoptes::RateLimitDumpWorker.min_delay,
        reject_with: Panoptes::RateLimitDumpWorker.reject_with,
        key: ->(resource_id, resource_type, medium_id, _requester_id=nil) {
          "#{resource_type}_#{resource_id}_#{medium_id}_data_dump_worker"
        },
        enabled: ->(_resource_id, _resource_type, _medium_id, requester_id=nil) {
          congestion_enabled?(requester_id)
        }
      }
  end

  module ClassMethods
    def congestion_enabled?(requester_id)
      # if the user is missing, should only happen via the rails console
      # false if the user is a special skip rate limit user
      return false if requester_id.blank? || Panoptes::RateLimitDumpWorker.skip_rate_limit_user_ids.include?(requester_id)

      user = User.find(requester_id)
      # false - disable congestion if user is admin
      # true - emable congestion if they are a normal user
      user.is_admin? ? false : true
    rescue ActiveRecord::RecordNotFound
      # if the user ID can't then enable congestion rate limiting
      # this may be the special case of a 'fake' internal user, e.g. -1
      true
    end
  end
end
