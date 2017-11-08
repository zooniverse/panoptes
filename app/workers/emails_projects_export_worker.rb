require 'csv'

class EmailsProjectsExportWorker
  include Sidekiq::Worker
  include DumpEmails

  sidekiq_options queue: :data_low

  def perform(project_id)
    @project = Project.find(project_id)
    @scope = CsvDumps::ProjectEmailList.new(project_id)

    begin
      perform_dump
      upload_dump
    ensure
      cleanup_dump
    end
  rescue ActiveRecord::RecordNotFound
  end

  def formatter
    @formatter ||= Formatter::Csv::UserEmail.new
  end

  private

  def export_type
    project.slug
  end
end
