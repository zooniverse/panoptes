require 'csv'

class WorkflowContentsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def formatter
    @formatter ||= Formatter::Csv::WorkflowContent.new
  end

  def get_scope(resource)
    @scope ||= CsvDumps::WorkflowContentScope.new(resource)
  end
end
