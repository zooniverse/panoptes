# frozen_string_literal: true

class DoorkeeperAccessCleanerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform
    DatabaseReplica.execute_without_timeout do
      Doorkeeper::AccessCleanup.new.cleanup!
    end
  end
end
