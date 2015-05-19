class MediumRemovalWorker
  include Sidekiq::Worker

  def perform(medium_src)
    MediaStorage.delete_file(medium_src)
  end
end
