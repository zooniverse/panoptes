class CalculateCompletenessWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly.minute_of_hour(0) }

  def perform
    Project.pluck(:id).each do |project_id|
      CalculateProjectCompletenessWorker.perform_async(project_id)
    end
  end
end
