require 'csv'

class WorkflowsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def formatter
    @formatter ||= Formatter::Csv::Workflow.new
  end

  def get_scope(resource)
    @scope ||= CsvDumps::WorkflowScope.new(resource)
  end
end
