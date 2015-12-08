class CalculateActivityWorker
  SPREAD = 30.minutes

  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { daily }

  def perform
    Project.pluck(:id).each do |project_id|
      CalculateProjectActivityWorker.perform_in(SPREAD*rand, project_id)
    end
  end
end
