require 'csv'

class WorkflowsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def perform_dump
    csv_formatter = Formatter::Csv::Workflow.new
    CSV.open(csv_file_path, 'wb') do |csv|
      csv << csv_formatter.class.headers
      project.workflows.find_each do |workflow|
        csv << csv_formatter.to_array(workflow)
        while workflow = workflow.previous_version
          csv << csv_formatter.to_array(workflow)
        end
      end
    end
  end
end
