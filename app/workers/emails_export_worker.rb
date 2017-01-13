class EmailsExportWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: :data_medium
  BETA_DELAY = 15.minutes.freeze
  PROJECT_SPREAD = 1.hour.freeze

  recurrence { daily.hour_of_day(3) }

  def perform
    if Panoptes.flipper[:export_emails].enabled?
      EmailsUsersExportWorker.perform_async(:global)
      EmailsUsersExportWorker.perform_in(BETA_DELAY, :beta)
      Project.launched.find_each do |p|
        EmailsProjectsExportWorker.perform_in(PROJECT_SPREAD * rand, p.id)
      end
    end
  end
end
