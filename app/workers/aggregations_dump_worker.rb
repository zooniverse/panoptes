class AggregationsDumpWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(resource_id, resource_type, medium_id=nil, requester_id=nil, *args)
    raise "No longer supported, nobody should be triggering this."
  end
end
