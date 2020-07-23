class MediumRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(medium_src, opts={})
    MediaStorage.delete_file(medium_src, opts)
  rescue Aws::S3::Errors::AccessDenied
  end
end
