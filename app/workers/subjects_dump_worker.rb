require 'csv'

class SubjectsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def formatter
    @formatter ||= Formatter::Csv::Subject.new(resource)
  end

  def get_scope(resource)
    CsvDumps::SubjectScope.new(resource)
  end
end
