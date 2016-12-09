class EmailsExportWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: :data_medium

  recurrence { daily.hour_of_day(3) }

  def perform
    if Panoptes.flipper[:export_emails].enabled?
      UsersEmailExportWorker.perform_async

    end
  end
end
