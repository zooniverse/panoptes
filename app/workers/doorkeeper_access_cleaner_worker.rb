class DoorkeeperAccessCleanerWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: :data_low

  recurrence { daily }

  def perform
    Doorkeeper::AccessCleanup.new.cleanup!
  end
end
