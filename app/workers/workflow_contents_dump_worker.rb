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

  def each
    read_from_database do
      resource.workflows.each do |workflow|
        workflow.workflow_contents.find_each do |wc|
          yield wc

          while wc = wc.previous_version
            yield wc
          end
        end
      end
    end
  end
end
