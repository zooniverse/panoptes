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

  def each
    read_from_database do
      resource.workflows.find_each do |workflow|
        yield workflow

        while workflow = workflow.previous_version
          yield workflow
        end
      end
    end
  end
end
