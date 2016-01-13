class RequeueClassificationsWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: :data_medium

  recurrence { hourly.minute_of_hour(0, 15, 30, 45)}

  def perform
    unless Panoptes.disable_lifecycle_worker

      non_lifecycled.find_in_batches do |classifications|
        classifications.each do |classification|
          ClassificationWorker.perform_async(classification.id, :create)
        end
      end

    end
  end

  private

  def non_lifecycled
    Classification
    .where(lifecycled_at: nil)
    .where("created_at <= ?", Panoptes.lifecycled_live_window.minutes.ago)
  end
end
