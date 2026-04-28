# frozen_string_literal: true

class SimulateLongJobWorker
  include Sidekiq::Worker

  sidekiq_options queue: :dumpworker

  def perform(duration_seconds)
    sleep(duration_seconds)
  end
end
