require 'csv'

class WorkflowsDumpWorker
  include Sidekiq::Worker
  include DumpWorker

  attr_reader :project

  def perform(project_id, medium_id=nil)
    if @project = Project.find(project_id)
      @medium_id = medium_id
      begin
        csv_formatter = Formatter::Csv::Workflow.new
        CSV.open(csv_file_path, 'wb') do |csv|
          csv << Formatter::Csv::Workflow.project_headers
          project.workflows.find_each do |workflow|
            csv << csv_formatter.to_array(workflow)
            while workflow = workflow.previous_version
              csv << csv_formatter.to_array(workflow)
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
