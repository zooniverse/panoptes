class ClassificationHeartbeatWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform
    if heartbeat_check? && missing_classifications?
      ClassificationHeartbeatMailer.missing_classifications(emails, window_period).deliver
      Honeybadger.notify(
        error_class:   "Classification data error",
        error_message: "No classification data received for #{window_period}"
      )
    end
  end

  private

  def missing_classifications?
    latest_receipt = Classification.last.created_at
    (DateTime.now.utc.to_i - latest_receipt.utc.to_i) > window_period
  end

  def window_period
    Panoptes::ClassificationHeartbeat.window_period
  end

  def emails
    Panoptes::ClassificationHeartbeat.emails
  end

  def heartbeat_check?
    Rails.env.production?
  end
end
