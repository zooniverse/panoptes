class AggregationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:dump_worker_exports].enabled?
    # Set expiry time of signed_url to one day from now
    medium.update!(put_expires: 1.day.from_now.to_i - Time.now.to_i)

    AggregationClient.new.aggregate(resource, medium)
  end

  def upload_dump
    # aggregation engine will write directly to medium when done, no need to upload
  end

  def cleanup_dump
    # aggregation engine will write directly to medium when done, no need to cleanup
  end

  def medium
    @medium ||= Medium.find(@medium_id).tap do |m|
      m.update!(path_opts: resource_file_path, private: true, content_type: "application/x-gzip")
    end
  end
end
