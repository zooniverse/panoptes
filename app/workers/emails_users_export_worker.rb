require 'csv'

class EmailsUsersExportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(export_type=:global)
    direct_to_s3 = CsvDumps::DirectToS3.new(export_type)
    formatter = Formatter::Csv::UserEmail.new
    scope = CsvDumps::FullEmailList.new(export_type)
    processor = CsvDumps::DumpProcessor.new(formatter, scope, direct_to_s3)
    processor.execute
  end
end
