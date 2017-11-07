require 'csv'

class EmailsUsersExportWorker
  include Sidekiq::Worker
  include DumpCommons
  include DumpEmails

  sidekiq_options queue: :data_low

  attr_reader :export_type

  def perform(export_type=:global)
    @export_type = export_type
    @scope = CsvDumps::FullEmailList.new(export_type)
    begin
      perform_dump
      upload_dump
    ensure
      cleanup_dump
    end
  end

  def formatter
    @formatter ||= Formatter::Csv::UserEmail.new
  end
end
