class CalculateActivityWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { daily }

  def perform
    Project.pluck(:id).each do |project_id|
      CalculateProjectActivityWorker.perform_async(project_id)
    end
  end
end
