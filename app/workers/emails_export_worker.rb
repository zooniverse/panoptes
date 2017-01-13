class EmailsExportWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  sidekiq_options queue: :data_medium
  SPREAD = 15.minutes.freeze

  recurrence { daily.hour_of_day(3) }

  def perform
    if Panoptes.flipper[:export_emails].enabled?
      EmailsUsersExportWorker.perform_async(:global)
      EmailsUsersExportWorker.perform_in(SPREAD, :beta)
      project_delay = SPREAD * 2
      Project.launched.find_each.with_index do |p, i|
        EmailsProjectsExportWorker.perform_in(project_delay + i, p.id)
      end
    end
  end
end
