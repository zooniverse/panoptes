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
      # if the user is missing, which should only happen via the rails console
      # TODO: determine if we want this?? or the automated subject set completion events
      return false if requester_id.blank?

      # Q? How will this work with the subject set export that is
      # intiated by an automated process and the requester_id is blank?
      # and thus not rate limited :(
      #
      # (will requester_id be blank or should it be?)
      #
      # we could add another param here to enforce rate limt
      # and pass in via worker call....TBD

      skip_user_ids = Panoptes::RateLimitDumpWorker.skip_rate_limit_user_ids

      if skip_user_ids.include?(requester_id)
        # false if the user is a special skip rate limit user
        false
      else
        # false if user is admin, true if not admin
        !User.find(requester_id).is_admin?
      end
    end
  end
end
