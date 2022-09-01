class DoorkeeperAccessCleanerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform
    Doorkeeper::AccessCleanup.new.cleanup!
  end
end
