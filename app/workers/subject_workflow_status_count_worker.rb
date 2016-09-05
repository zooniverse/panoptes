class SubjectWorkflowStatusCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  sidekiq_options congestion: {
    interval: ENV.fetch("sws_count_worker_interval", 30),
    max_in_interval: ENV.fetch("sws_count_worker_max_in_interval", 1),
    min_delay: 0,
    reject_with: ENV.fetch("sws_count_worker_reject_with", :cancel),
    key: ->(count_id) {
      "sws_#{count_id}_count_worker"
    }
  }

  def perform(count_id)
    sws = SubjectWorkflowStatus.find(count_id)
    counter = SubjectWorkflowCounter.new(sws)
    sws.update_column(:classifications_count, counter.classifications)
  end
end
