class SubjectWorkflowStatusCountWorker
  include Sidekiq::Worker

  sidekiq_options queue: :really_high

  sidekiq_options congestion: {
    interval: 30,
    max_in_interval: 1,
    min_delay: 5,
    reject_with: :reschedule,
    key: ->(count_id) {
      "sws_#{count_id}_count_worker"
    }
  }

  sidekiq_options lock: :until_executing

  def perform(count_id)
    sws = SubjectWorkflowStatus.find(count_id)
    counter = SubjectWorkflowCounter.new(sws)
    sws.update_column(:classifications_count, counter.classifications)
  end
end
