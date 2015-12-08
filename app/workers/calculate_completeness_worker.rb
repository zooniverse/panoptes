class CalculateCompletenessWorker
  SPREAD = 30.minutes

  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly.minute_of_hour(0) }

  def perform
    Project.pluck(:id).each do |project_id|
      CalculateProjectCompletenessWorker.perform_in(SPREAD*rand, project_id)
    end
  end
end
