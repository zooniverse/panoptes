class MediumRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(medium_src)
    MediaStorage.delete_file(medium_src)
  rescue Aws::S3::Errors::AccessDenied
  end
end
