require 'csv'

class WorkflowContentsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  attr_reader :project

  def perform(project_id, medium_id=nil)
    if @project = Project.find(project_id)
      @medium_id = medium_id
      begin
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
        to_gzip
        write_to_s3
        set_ready_state
        send_email
      ensure
        FileUtils.rm(csv_file_path)
        FileUtils.rm(gzip_file_path)
      end
    end
  end
end
