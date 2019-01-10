require 'csv'

class WorkflowContentsDumpWorker
  include Sidekiq::Worker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform(resource_id, resource_type, medium_id=nil, requester_id=nil, *args)
    # No longer in use, but left worker in so that any job still in queue
    # doesn't crash upon deploy.
    nil
  end
end
