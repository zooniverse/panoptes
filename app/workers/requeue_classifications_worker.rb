class RequeueClassificationsWorker

  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly.minute_of_hour(0, 15, 30, 45)}

  def perform
    non_lifecycled.find_in_batches do |classifications|
      classifications.each do |classification|
        ClassificationLifecycle.new(classification).queue(:create)
      end
    end
  end

  private

  def non_lifecycled
    Classification.where(lifecycled_at: nil)
  end
end
