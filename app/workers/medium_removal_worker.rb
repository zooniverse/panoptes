# frozen_string_literal: true

class MediumRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(medium_src, opts={})
    MediaStorage.delete_file(object_store_path(medium_src), opts)
  rescue Aws::S3::Errors::AccessDenied, Azure::Core::Http::HTTPError
    # do nothing and don't retry this worker
  end

  private

  def object_store_path(path)
    # only when cleaning up azure objects do the paths need modification
    return path unless MediaStorage.get_adapter.is_a?(MediaStorage::AzureAdapter)

    # azure paths may need to have the s3 specific storage paths
    # converted to match the new azure object store location paths
    # i.e. remove the custom s3 path prefix (hosted_domain/rails_env)
    # from the resulting object store path vs what we've stored in the db
    #
    # note: this path modification is a vestige of our s3 -> azure cloud migration
    #       specifically the medium.src db values for our exising s3 data that was mapped
    #       to a different storage account, container path in azure
    MediaStorage::StoredPath.media_path(path)
  end
end
