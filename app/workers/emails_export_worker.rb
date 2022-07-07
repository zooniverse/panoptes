class EmailsExportWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: :data_medium
  BETA_DELAY = 15.minutes.freeze
  NASA_DELAY = 30.minutes.freeze
  PROJECT_SPREAD = 1.hour.freeze

  recurrence { daily.hour_of_day(3) }

  def perform
    return unless Flipper.enabled?(:export_emails)

    EmailsUsersExportWorker.perform_async(:global)
    EmailsUsersExportWorker.perform_in(BETA_DELAY, :beta)
    EmailsUsersExportWorker.perform_in(NASA_DELAY, :nasa)
    Project.launched.find_each do |p|
      EmailsProjectsExportWorker.perform_in(PROJECT_SPREAD * rand, p.id)
    end
  end
end
