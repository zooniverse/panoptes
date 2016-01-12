class CalculateCompletenessWorker
  SPREAD = 30.minutes

  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: :data_medium

  recurrence { hourly.minute_of_hour(0) }

  def perform
    Project.active.pluck(:id).each do |project_id|
      CalculateProjectCompletenessWorker.perform_in(SPREAD*rand, project_id)
    end
  end
end
