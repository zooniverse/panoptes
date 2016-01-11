require 'csv'

class WorkflowContentsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    csv_formatter = Formatter::Csv::WorkflowContent.new
    CSV.open(csv_file_path, 'wb') do |csv|
      csv << csv_formatter.class.headers
      project.workflows.each do |workflow|
        workflow.workflow_contents.find_each do |wc|
          csv << csv_formatter.to_array(wc)
          while wc = wc.previous_version
            csv << csv_formatter.to_array(wc)
          end
        end
      end
    end
  end
end
